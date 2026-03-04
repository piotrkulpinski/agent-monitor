import Foundation
import Darwin
import SQLite3

struct OpenCodeDetector: AgentDetector {
    let agentType: AgentType = .openCode

    private let dbPath = NSHomeDirectory() + "/.local/share/opencode/opencode.db"

    func detect() async -> [AgentInstance] {
        let pids = getAllPIDs()
        let sessionData = loadSessionData()
        var instances: [AgentInstance] = []

        for pid in pids {
            guard isOpenCodeProcess(pid) else { continue }
            guard let cwd = getWorkingDirectory(pid) else { continue }

            let startTime = getProcessStartTime(pid) ?? Date()
            let normalizedCWD = NSString(string: cwd).standardizingPath
            let modelName = sessionData[normalizedCWD] ?? sessionData[cwd]

            if getParentPID(pid) == 1 {
                // PPID=1 identifies daemon OpenCode processes; ProcessTreeResolver will use this.
            }

            instances.append(
                AgentInstance(
                    agentType: .openCode,
                    pid: pid,
                    workingDirectory: cwd,
                    modelName: modelName,
                    sessionStartTime: startTime
                )
            )
        }

        return instances
    }

    private func getAllPIDs() -> [pid_t] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }

        var pids = [pid_t](repeating: 0, count: Int(count) + 16)
        let actual = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard actual > 0 else { return [] }

        return pids.prefix(Int(actual)).filter { $0 > 0 }
    }

    private func isOpenCodeProcess(_ pid: pid_t) -> Bool {
        var name = [CChar](repeating: 0, count: Int(MAXCOMLEN) + 1)
        let nameResult = proc_name(pid, &name, UInt32(name.count))
        guard nameResult > 0, String(cString: name) == ".opencode" else { return false }

        // Real Open Code processes are Node.js binaries that rename themselves via process.title.
        // Their proc_pidpath returns empty. Unrelated processes that coincidentally show '.opencode'
        // as proc_name (e.g. Wispr Flow, TablePlus Sparkle) have a non-empty pidpath — exclude them.
        var pathBuf = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let pathResult = proc_pidpath(pid, &pathBuf, UInt32(pathBuf.count))
        return pathResult <= 0 || String(cString: pathBuf).isEmpty
    }

    private func getWorkingDirectory(_ pid: pid_t) -> String? {
        var vnodeInfo = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &vnodeInfo, size)
        guard result > 0 else { return nil }

        return withUnsafePointer(to: &vnodeInfo.pvi_cdir.vip_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { cstr in
                let path = String(cString: cstr)
                return path.isEmpty ? nil : path
            }
        }
    }

    private func getProcessStartTime(_ pid: pid_t) -> Date? {
        var bsdInfo = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, size)
        guard result > 0 else { return nil }

        let seconds = TimeInterval(bsdInfo.pbi_start_tvsec)
        let microseconds = TimeInterval(bsdInfo.pbi_start_tvusec) / 1_000_000
        return Date(timeIntervalSince1970: seconds + microseconds)
    }

    private func getParentPID(_ pid: pid_t) -> pid_t? {
        var bsdInfo = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, size)
        guard result > 0 else { return nil }
        return pid_t(bsdInfo.pbi_ppid)
    }

    private func loadSessionData() -> [String: String] {
        guard FileManager.default.fileExists(atPath: dbPath) else { return [:] }

        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let db else {
            return [:]
        }
        defer { sqlite3_close(db) }

        sqlite3_exec(db, "PRAGMA query_only = ON", nil, nil, nil)

        let sql = """
            WITH model_rows AS (
                SELECT
                    s.directory,
                    json_extract(m.data, '$.modelID') AS model_name,
                    m.time_created,
                    m.rowid,
                    ROW_NUMBER() OVER (
                        PARTITION BY s.directory
                        ORDER BY m.time_created DESC, m.rowid DESC
                    ) AS rank
                FROM session s
                JOIN message m ON m.session_id = s.id
                WHERE json_extract(m.data, '$.modelID') IS NOT NULL
            )
            SELECT directory, model_name
            FROM model_rows
            WHERE rank = 1
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            return [:]
        }
        defer { sqlite3_finalize(stmt) }

        var rows: [String: String] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard
                let dirPtr = sqlite3_column_text(stmt, 0),
                let modelPtr = sqlite3_column_text(stmt, 1)
            else { continue }

            let directory = String(cString: dirPtr)
            let modelName = String(cString: modelPtr)
            guard !directory.isEmpty, !modelName.isEmpty else { continue }

            rows[directory] = modelName
            rows[NSString(string: directory).standardizingPath] = modelName
        }

        return rows
    }
}

import Foundation
import Darwin

struct ClaudeCodeDetector: AgentDetector {
    let agentType: AgentType = .claudeCode

    func detect() async -> [AgentInstance] {
        let pids = getAllPIDs()
        var instances: [AgentInstance] = []

        for pid in pids {
            guard isClaudeProcess(pid) else { continue }
            guard let cwd = getWorkingDirectory(pid) else { continue }
            let startTime = getProcessStartTime(pid) ?? Date()
            let sessionTitle = getSessionTitle(for: cwd)

            instances.append(
                AgentInstance(
                    agentType: .claudeCode,
                    pid: pid,
                    workingDirectory: cwd,
                    sessionTitle: sessionTitle,
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

    private func isClaudeProcess(_ pid: pid_t) -> Bool {
        // Claude Code now ships versioned binaries at:
        // ~/.local/share/claude/versions/2.x.y
        // proc_name returns the version string (e.g. "2.1.63"), not "claude"
        // Use proc_pidpath to check the full executable path instead.
        var pathBuf = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let result = proc_pidpath(pid, &pathBuf, UInt32(pathBuf.count))
        guard result > 0 else { return false }
        let path = String(cString: pathBuf)
        return path.contains("/claude/") || path.hasSuffix("/claude")
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
}

    /// Reads the session title from ~/.claude/usage-data/session-meta/ for the most recent
    /// session in the given working directory. Returns nil if not found or no summary available.
    private func getSessionTitle(for cwd: String) -> String? {
        // Claude Code stores projects as dirs named by replacing '/' with '-' in the path.
        // e.g. /Users/foo/Sites/bar -> -Users-foo-Sites-bar
        let projectDirName = cwd.replacingOccurrences(of: "/", with: "-")
        let projectDir = NSHomeDirectory() + "/.claude/projects/" + projectDirName
        let sessionMetaDir = NSHomeDirectory() + "/.claude/usage-data/session-meta"

        guard FileManager.default.fileExists(atPath: projectDir) else { return nil }

        // Find the most recently modified JSONL in the project dir (= most recent session).
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: projectDir) else { return nil }
        let jsonlFiles = files.filter { $0.hasSuffix(".jsonl") && !$0.contains("/") }
        guard !jsonlFiles.isEmpty else { return nil }

        // Pick the most recently modified JSONL.
        let mostRecent = jsonlFiles
            .compactMap { name -> (String, Date)? in
                let path = projectDir + "/" + name
                guard let attrs = try? fm.attributesOfItem(atPath: path),
                      let mod = attrs[.modificationDate] as? Date else { return nil }
                return (name, mod)
            }
            .max(by: { $0.1 < $1.1 })
            .map { $0.0 }

        guard let jsonlName = mostRecent else { return nil }
        let sessionUUID = String(jsonlName.dropLast(6)) // strip .jsonl

        // Try session-meta first (has AI-generated summary).
        let metaPath = sessionMetaDir + "/" + sessionUUID + ".json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: metaPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let summary = json["summary"] as? String, !summary.isEmpty {
            return summary
        }

        return nil
    }

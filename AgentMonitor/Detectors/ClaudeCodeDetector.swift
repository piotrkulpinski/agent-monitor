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

            instances.append(
                AgentInstance(
                    agentType: .claudeCode,
                    pid: pid,
                    workingDirectory: cwd,
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
        var name = [CChar](repeating: 0, count: Int(MAXCOMLEN) + 1)
        let result = proc_name(pid, &name, UInt32(name.count))
        guard result > 0 else { return false }

        return String(cString: name) == "claude"
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

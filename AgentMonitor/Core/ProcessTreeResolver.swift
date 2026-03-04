import Foundation
import Darwin

struct ProcessTreeResolver {
    // Match case-insensitively — proc_name returns "ghostty" (lowercase) on some versions.
    // Zed has a built-in terminal and is a common host for AI agents.
    private static let terminalAppNames: Set<String> = [
        "ghostty", "terminal", "iterm2", "kitty", "warp", "wezterm", "alacritty", "rio",
        "hyper", "tabby", "fig", "zed"
    ]

    private static let maxDepth = 15

    func resolve(pid: pid_t) -> ProcessTreeInfo {
        var currentPID = pid
        var depth = 0

        while depth < Self.maxDepth {
            // Use sysctl as primary — it works for setuid processes like /usr/bin/login
            // that proc_pidinfo(PROC_PIDTBSDINFO) cannot read.
            guard let ppid = getParentPID(currentPID), ppid > 1 else {
                return .noTerminal
            }

            let parentName = (getProcessName(ppid) ?? "").lowercased()

            if Self.terminalAppNames.contains(parentName) {
                return ProcessTreeInfo(
                    terminalPID: ppid,
                    terminalAppName: parentName,
                    canFocusTerminal: true
                )
            }

            currentPID = ppid
            depth += 1
        }

        return .noTerminal
    }

    private func getParentPID(_ pid: pid_t) -> pid_t? {
        // Primary: sysctl KERN_PROC_PID — works for all processes including setuid login
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        let ret = sysctl(&mib, 4, &info, &size, nil, 0)
        if ret == 0 && size > 0 {
            let ppid = pid_t(info.kp_eproc.e_ppid)
            if ppid > 0 { return ppid }
        }

        // Fallback: proc_pidinfo (fails for setuid processes like login)
        var bsdInfo = proc_bsdinfo()
        let result = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo,
                                  Int32(MemoryLayout<proc_bsdinfo>.size))
        guard result > 0 else { return nil }
        let ppid = pid_t(bsdInfo.pbi_ppid)
        return ppid > 0 ? ppid : nil
    }

    private func getProcessName(_ pid: pid_t) -> String? {
        var name = [CChar](repeating: 0, count: 256)  // 256, not MAXCOMLEN+1=17
        let result = proc_name(pid, &name, UInt32(name.count))
        guard result > 0 else { return nil }
        let s = String(cString: name)
        return s.isEmpty ? nil : s
    }
}

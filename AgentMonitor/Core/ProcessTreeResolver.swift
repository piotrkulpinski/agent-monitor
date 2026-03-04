import Foundation
import Darwin

struct ProcessTreeResolver {
    private static let terminalAppNames: Set<String> = [
        "Ghostty", "Terminal", "iTerm2", "kitty", "Warp", "WezTerm", "Alacritty", "rio",
        "Hyper", "Tabby", "Fig"
    ]

    private static let maxDepth = 10

    func resolve(pid: pid_t) -> ProcessTreeInfo {
        var currentPID = pid
        var depth = 0

        while depth < Self.maxDepth {
            guard let ppid = getParentPID(currentPID), ppid > 1 else {
                return .noTerminal
            }

            let parentName = getProcessName(ppid) ?? ""

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
        var bsdInfo = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, size)
        guard result > 0 else { return nil }
        let ppid = bsdInfo.pbi_ppid
        return ppid > 0 ? pid_t(ppid) : nil
    }

    private func getProcessName(_ pid: pid_t) -> String? {
        var name = [CChar](repeating: 0, count: Int(MAXCOMLEN) + 1)
        let result = proc_name(pid, &name, UInt32(name.count))
        guard result > 0 else { return nil }
        let s = String(cString: name)
        return s.isEmpty ? nil : s
    }
}

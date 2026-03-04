import Foundation

struct ProcessTreeInfo {
    let terminalPID: pid_t?
    let terminalAppName: String?
    let canFocusTerminal: Bool

    static let noTerminal = ProcessTreeInfo(
        terminalPID: nil,
        terminalAppName: nil,
        canFocusTerminal: false
    )
}

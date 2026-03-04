import AppKit
import ApplicationServices

@MainActor
final class FocusTerminalService {
    static let shared = FocusTerminalService()

    private init() {}

    func focus(agent: AgentInstance) {
        let treeInfo = ProcessTreeResolver().resolve(pid: agent.pid)
        guard treeInfo.canFocusTerminal, let terminalPID = treeInfo.terminalPID else {
            return
        }

        guard let app = NSRunningApplication(processIdentifier: terminalPID) else {
            return
        }

        if AXIsProcessTrusted() {
            raiseWindowWithAccessibility(terminalPID: terminalPID, app: app)
        } else {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }

    private func raiseWindowWithAccessibility(terminalPID: pid_t, app: NSRunningApplication) {
        let axApp = AXUIElementCreateApplication(terminalPID)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
            app.activate(options: .activateIgnoringOtherApps)
            return
        }

        AXUIElementPerformAction(windows[0], kAXRaiseAction as CFString)
        app.activate(options: .activateIgnoringOtherApps)
    }
}

import UserNotifications
import Foundation

@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()

    private var lastNotificationTime: [pid_t: Date] = [:]
    private var workingStartTime: [pid_t: Date] = [:]

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func agentStartedWorking(_ agent: AgentInstance) {
        workingStartTime[agent.pid] = Date()
    }

    func agentCompletedWork(_ agent: AgentInstance) {
        let now = Date()

        if let startTime = workingStartTime[agent.pid] {
            let d = now.timeIntervalSince(startTime)
            guard d >= 5.0 else {
                workingStartTime.removeValue(forKey: agent.pid)
                return
            }
        }
        workingStartTime.removeValue(forKey: agent.pid)

        if let lastTime = lastNotificationTime[agent.pid] {
            let elapsed = now.timeIntervalSince(lastTime)
            guard elapsed >= 30.0 else { return }
        }
        lastNotificationTime[agent.pid] = now

        sendNotification(for: agent)
    }

    private func sendNotification(for agent: AgentInstance) {
        let content = UNMutableNotificationContent()
        content.title = "\(agent.agentType.displayName) finished"
        content.body = "\(agent.projectName) is now idle"
        content.sound = .default
        content.userInfo = ["pid": agent.pid]

        let request = UNNotificationRequest(
            identifier: "agent-completed-\(agent.pid)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let pidValue = userInfo["pid"] as? Int32 {
            let pid = pid_t(pidValue)
            Task { @MainActor in
                FocusTerminalService.shared.focus(pid: pid)
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

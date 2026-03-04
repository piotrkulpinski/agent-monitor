import UserNotifications
import Foundation

@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()

    // Tracks when each PID last transitioned working->idle (for throttle)
    private var lastNotificationTime: [pid_t: Date] = [:]
    // Tracks when each PID first became working (for debounce)
    private var workingStartTime: [pid_t: Date] = [:]

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func agentStartedWorking(_ agent: AgentInstance) {
        workingStartTime[agent.pid] = Date()
    }

    func agentCompletedWork(_ agent: AgentInstance) {
        let now = Date()

        // Debounce: must have been working for at least 5 seconds
        if let startTime = workingStartTime[agent.pid] {
            let workDuration = now.timeIntervalSince(startTime)
            guard workDuration >= 5.0 else {
                workingStartTime.removeValue(forKey: agent.pid)
                return
            }
        }
        workingStartTime.removeValue(forKey: agent.pid)

        // Throttle: max one notification per agent per 30 seconds
        if let lastTime = lastNotificationTime[agent.pid] {
            guard now.timeIntervalSince(lastTime) >= 30.0 else { return }
        }
        lastNotificationTime[agent.pid] = now

        sendNotification(for: agent)
    }

    private func sendNotification(for agent: AgentInstance) {
        let content = UNMutableNotificationContent()
        content.title = "\(agent.agentType.displayName) finished"
        content.body = "\(agent.projectName) is now idle"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "agent-completed-\(agent.pid)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
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

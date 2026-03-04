import SwiftUI

@main
struct AgentMonitorApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var monitorService = AgentMonitorService(detectors: [
        ClaudeCodeDetector(), OpenCodeDetector()
    ])
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        MenuBarExtra("AgentMonitor", systemImage: menuBarManager.currentImageName) {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                AgentListView()
                    .environmentObject(monitorService)
                    .environmentObject(menuBarManager)
                    .onAppear {
                        monitorService.startMonitoring()
                        monitorService.onAgentCompleted = { agent in
                            NotificationService.shared.agentCompletedWork(agent)
                        }
                        NotificationService.shared.requestPermission()
                    }
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: monitorService.agents) { _, agents in
            menuBarManager.update(from: agents)
        }
    }
}

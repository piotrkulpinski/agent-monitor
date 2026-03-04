import SwiftUI

@main
struct AgentMonitorApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var monitorService: AgentMonitorService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        // Wire notifications and start monitoring at app launch — before any UI appears.
        // If wired in onAppear (popover open), working→idle transitions that happen before
        // the user ever opens the popover are silently dropped.
        let service = AgentMonitorService(detectors: [ClaudeCodeDetector(), OpenCodeDetector()])
        service.onAgentCompleted = { agent in
            NotificationService.shared.agentCompletedWork(agent)
        }
        service.startMonitoring()
        _monitorService = StateObject(wrappedValue: service)
    }

    var body: some Scene {
        MenuBarExtra("AgentMonitor", image: menuBarManager.currentImageName) {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                AgentListView()
                    .environmentObject(monitorService)
                    .environmentObject(menuBarManager)
                    .onAppear {
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

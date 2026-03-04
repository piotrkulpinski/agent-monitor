import SwiftUI

@main
struct AgentMonitorApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var monitorService = AgentMonitorService(detectors: [
        ClaudeCodeDetector(), OpenCodeDetector()
    ])

    var body: some Scene {
        MenuBarExtra("AgentMonitor", systemImage: menuBarManager.currentImageName) {
            AgentListView()
                .environmentObject(monitorService)
                .environmentObject(menuBarManager)
                .onAppear { monitorService.startMonitoring() }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: monitorService.agents) { _, agents in
            menuBarManager.update(from: agents)
        }
    }
}

import SwiftUI

@main
struct AgentMonitorApp: App {
    @StateObject private var menuBarManager = MenuBarManager()

    var body: some Scene {
        MenuBarExtra("AgentMonitor", systemImage: menuBarManager.currentImageName) {
            ContentView()
                .environmentObject(menuBarManager)
        }
        .menuBarExtraStyle(.window)
    }
}

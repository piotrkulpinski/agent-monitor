import SwiftUI

@main
struct AgentMonitorApp: App {
    var body: some Scene {
        MenuBarExtra("AgentMonitor", systemImage: "circle.dotted") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}

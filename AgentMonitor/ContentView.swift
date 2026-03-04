import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("AgentMonitor")
                .font(.headline)
            Text("No agents detected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 320, height: 120)
        .padding()
    }
}

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cpu")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No AI agents detected")
                .font(.headline)
            Text("Start Claude Code or Open Code\nto begin monitoring.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

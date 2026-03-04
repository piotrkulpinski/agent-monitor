import SwiftUI
import ServiceManagement

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Welcome to AgentMonitor")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Monitor your AI coding agents from the menu bar.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get notified when agents finish work"
                )
                PermissionRow(
                    icon: "accessibility",
                    title: "Accessibility (Optional)",
                    description: "Focus the exact terminal window of an agent"
                )
            }

            Button("Get Started") {
                NotificationService.shared.requestPermission()
                hasCompletedOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
        .frame(width: 320)
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

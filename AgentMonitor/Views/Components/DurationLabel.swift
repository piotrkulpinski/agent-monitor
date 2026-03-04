import SwiftUI

struct DurationLabel: View {
    let startTime: Date

    var duration: String {
        let seconds = Int(Date().timeIntervalSince(startTime))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "<1m"
    }

    var body: some View {
        Text(duration)
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
}

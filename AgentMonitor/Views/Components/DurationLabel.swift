import SwiftUI

struct DurationLabel: View {
    let date: Date

    var label: String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
}

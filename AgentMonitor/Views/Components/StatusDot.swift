import SwiftUI

struct StatusDot: View {
    let state: ActivityState

    var color: Color {
        switch state {
        case .working: return .green
        case .idle: return .secondary
        case .unknown: return .yellow
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

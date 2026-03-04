import Foundation

enum MenuBarIconState: Equatable {
    case inactive   // No agents detected
    case idle       // Agents present, all idle
    case active     // At least one agent working

    var systemImageName: String {
        switch self {
        case .inactive: return "circle.dashed"
        case .idle:     return "circle.fill"
        case .active:   return "circle.fill"
        }
    }

    // Alternate image for active animation (toggled every 0.5s)
    var alternateSystemImageName: String {
        return "circle.dotted"
    }
}

import Foundation

enum MenuBarIconState: Equatable {
    case inactive   // No agents detected
    case idle       // Agents present, all idle
    case active     // At least one agent working

    var imageName: String {
        switch self {
        case .inactive: return "MenuBarInactive"
        case .idle:     return "MenuBarIdle"
        case .active:   return "MenuBarActive"
        }
    }

    // Alternate image for active animation (toggled every 0.5s)
    var alternateImageName: String {
        switch self {
        case .active: return "MenuBarIdle"  // animation: toggle between active and idle
        default: return imageName
        }
    }
}

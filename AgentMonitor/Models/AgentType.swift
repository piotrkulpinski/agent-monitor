import Foundation

enum AgentType: String, CaseIterable, Identifiable {
    case claudeCode = "Claude Code"
    case openCode = "Open Code"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .openCode: return "Open Code"
        }
    }
}

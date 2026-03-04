import Foundation

enum AgentType: String, CaseIterable, Identifiable {
    case claudeCode = "Claude Code"
    case openCode = "Open Code"

    var id: String { rawValue }
}

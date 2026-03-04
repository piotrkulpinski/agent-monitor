import Foundation

protocol AgentDetector {
    var agentType: AgentType { get }
    func detect() async -> [AgentInstance]
}

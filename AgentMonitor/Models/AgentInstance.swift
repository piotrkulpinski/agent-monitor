import Foundation

struct AgentInstance: Identifiable {
    let id: UUID
    let agentType: AgentType
    let pid: pid_t
    let workingDirectory: String
    var modelName: String?
    var contextWindowUsage: Double?
    let sessionStartTime: Date
    var activityState: ActivityState

    var projectName: String {
        URL(fileURLWithPath: workingDirectory).lastPathComponent
    }

    init(
        id: UUID = UUID(),
        agentType: AgentType,
        pid: pid_t,
        workingDirectory: String,
        modelName: String? = nil,
        contextWindowUsage: Double? = nil,
        sessionStartTime: Date = Date(),
        activityState: ActivityState = .unknown
    ) {
        self.id = id
        self.agentType = agentType
        self.pid = pid
        self.workingDirectory = workingDirectory
        self.modelName = modelName
        self.contextWindowUsage = contextWindowUsage
        self.sessionStartTime = sessionStartTime
        self.activityState = activityState
    }
}

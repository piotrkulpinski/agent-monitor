import Foundation

struct AgentInstance: Identifiable, Equatable {
    let id: UUID
    let agentType: AgentType
    let pid: pid_t
    let workingDirectory: String
    var modelName: String?
    var sessionTitle: String?
    var contextWindowUsage: Double?
    let sessionStartTime: Date
    var activityState: ActivityState

    var displayTitle: String {
        sessionTitle ?? projectName
    }

    var projectName: String {
        URL(fileURLWithPath: workingDirectory).lastPathComponent
    }

    var shortWorkingDirectory: String {
        let home = NSHomeDirectory()
        if workingDirectory.hasPrefix(home) {
            return "~" + workingDirectory.dropFirst(home.count)
        }
        return workingDirectory
    }

    init(
        id: UUID = UUID(),
        agentType: AgentType,
        pid: pid_t,
        workingDirectory: String,
        modelName: String? = nil,
        sessionTitle: String? = nil,
        contextWindowUsage: Double? = nil,
        sessionStartTime: Date = Date(),
        activityState: ActivityState = .unknown
    ) {
        self.id = id
        self.agentType = agentType
        self.pid = pid
        self.workingDirectory = workingDirectory
        self.modelName = modelName
        self.sessionTitle = sessionTitle
        self.contextWindowUsage = contextWindowUsage
        self.sessionStartTime = sessionStartTime
        self.activityState = activityState
    }
}

import XCTest
@testable import AgentMonitor

final class AgentInstanceTests: XCTestCase {

    func testProjectNameExtractsLastPathComponent() {
        let agent = AgentInstance(
            agentType: .claudeCode,
            pid: 1234,
            workingDirectory: "/Users/user/Sites/my-project"
        )
        XCTAssertEqual(agent.projectName, "my-project")
    }

    func testProjectNameWithTrailingSlash() {
        let agent = AgentInstance(
            agentType: .claudeCode,
            pid: 1234,
            workingDirectory: "/Users/user/Sites/my-project/"
        )
        // URL.lastPathComponent handles trailing slash
        XCTAssertFalse(agent.projectName.isEmpty)
    }

    func testProjectNameForRootDirectory() {
        let agent = AgentInstance(
            agentType: .openCode,
            pid: 5678,
            workingDirectory: "/"
        )
        XCTAssertFalse(agent.projectName.isEmpty)
    }

    func testDefaultActivityStateIsUnknown() {
        let agent = AgentInstance(
            agentType: .claudeCode,
            pid: 1234,
            workingDirectory: "/tmp/test"
        )
        XCTAssertEqual(agent.activityState, .unknown)
    }

    func testModelNameIsNilByDefault() {
        let agent = AgentInstance(
            agentType: .claudeCode,
            pid: 1234,
            workingDirectory: "/tmp/test"
        )
        XCTAssertNil(agent.modelName)
    }

    func testAgentTypeDisplayName() {
        XCTAssertEqual(AgentType.claudeCode.displayName, "Claude Code")
        XCTAssertEqual(AgentType.openCode.displayName, "Open Code")
    }
}

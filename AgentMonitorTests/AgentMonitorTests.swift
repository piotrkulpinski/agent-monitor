import XCTest
@testable import AgentMonitor

// Main test file — additional integration-style tests

final class AgentMonitorTests: XCTestCase {

    func testActivityStateEquality() {
        XCTAssertEqual(ActivityState.working, ActivityState.working)
        XCTAssertEqual(ActivityState.idle, ActivityState.idle)
        XCTAssertEqual(ActivityState.unknown, ActivityState.unknown)
        XCTAssertNotEqual(ActivityState.working, ActivityState.idle)
    }

    func testAgentTypeEquality() {
        XCTAssertEqual(AgentType.claudeCode, AgentType.claudeCode)
        XCTAssertEqual(AgentType.openCode, AgentType.openCode)
        XCTAssertNotEqual(AgentType.claudeCode, AgentType.openCode)
    }

    func testAgentInstanceIdentifiable() {
        let agent1 = AgentInstance(agentType: .claudeCode, pid: 1, workingDirectory: "/tmp/a")
        let agent2 = AgentInstance(agentType: .claudeCode, pid: 2, workingDirectory: "/tmp/b")
        XCTAssertNotEqual(agent1.id, agent2.id)
    }

    func testMenuBarIconStateInactive() {
        let state = MenuBarIconState.inactive
        XCTAssertFalse(state.imageName.isEmpty)
    }

    func testMenuBarIconStateIdle() {
        let state = MenuBarIconState.idle
        XCTAssertFalse(state.imageName.isEmpty)
    }

    func testMenuBarIconStateActive() {
        let state = MenuBarIconState.active
        XCTAssertFalse(state.imageName.isEmpty)
        XCTAssertFalse(state.alternateImageName.isEmpty)
    }
}

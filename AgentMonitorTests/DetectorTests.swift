import XCTest
@testable import AgentMonitor

final class DetectorTests: XCTestCase {

    // MARK: - ClaudeCodeDetector

    func testClaudeCodeDetectorReturnsArray() async {
        let detector = ClaudeCodeDetector()
        let agents = await detector.detect()
        XCTAssertNotNil(agents)
    }

    func testClaudeCodeDetectorAgentsHaveCorrectType() async {
        let detector = ClaudeCodeDetector()
        let agents = await detector.detect()
        for agent in agents {
            XCTAssertEqual(agent.agentType, .claudeCode)
        }
    }

    // MARK: - OpenCodeDetector

    func testOpenCodeDetectorReturnsArray() async {
        let detector = OpenCodeDetector()
        let agents = await detector.detect()
        XCTAssertNotNil(agents)
    }

    func testOpenCodeDetectorAgentsHaveCorrectType() async {
        let detector = OpenCodeDetector()
        let agents = await detector.detect()
        for agent in agents {
            XCTAssertEqual(agent.agentType, .openCode)
        }
    }

    // MARK: - ActivityMonitor

    @MainActor
    func testActivityMonitorFirstSampleSetsUnknown() {
        let monitor = ActivityMonitor()
        var agents = [
            AgentInstance(agentType: .claudeCode, pid: getpid(), workingDirectory: "/tmp")
        ]
        monitor.updateActivityStates(for: &agents)
        // First sample for any PID → .unknown (no previous delta)
        XCTAssertEqual(agents[0].activityState, .unknown)
    }

    @MainActor
    func testActivityMonitorNonExistentPIDStaysUnknown() {
        let monitor = ActivityMonitor()
        var agents = [
            AgentInstance(agentType: .claudeCode, pid: 99999, workingDirectory: "/tmp")
        ]
        monitor.updateActivityStates(for: &agents)
        // proc_pidinfo fails for non-existent PID → state unchanged from default .unknown
        XCTAssertEqual(agents[0].activityState, .unknown)
    }
}

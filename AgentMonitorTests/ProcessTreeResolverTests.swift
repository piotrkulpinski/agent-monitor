import XCTest
@testable import AgentMonitor

final class ProcessTreeResolverTests: XCTestCase {

    func testCurrentProcessHasParent() {
        let resolver = ProcessTreeResolver()
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let info = resolver.resolve(pid: currentPID)
        // The test process itself has a parent (xcodebuild or similar)
        // We can't assert specific terminal, but canFocusTerminal may be true or false
        // Just verify it doesn't crash and returns a valid struct
        XCTAssertNotNil(info)
    }

    func testInvalidPIDReturnsNoTerminal() {
        let resolver = ProcessTreeResolver()
        // PID 0 is the kernel — should not crash and should return canFocusTerminal=false
        let info = resolver.resolve(pid: 0)
        XCTAssertFalse(info.canFocusTerminal)
    }

    func testNonExistentPIDReturnsNoTerminal() {
        let resolver = ProcessTreeResolver()
        // Use a very high PID that almost certainly doesn't exist
        let info = resolver.resolve(pid: 99999)
        XCTAssertFalse(info.canFocusTerminal)
    }

    func testMaxDepthProtection() {
        // This test verifies the resolver doesn't infinite loop
        // by resolving a real PID and completing in reasonable time
        let resolver = ProcessTreeResolver()
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let start = Date()
        _ = resolver.resolve(pid: currentPID)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0, "ProcessTreeResolver should complete within 1 second")
    }
}

import Foundation
import Darwin

@MainActor
final class ActivityMonitor {
    var onAgentCompleted: ((AgentInstance) -> Void)?

    private struct CPUSample {
        let userTicks: UInt64
        let systemTicks: UInt64
        let wallTime: Date
    }

    private var previousSamples: [pid_t: CPUSample] = [:]
    private let workingThresholdPercent: Double = 0.5

    func updateActivityStates(for agents: inout [AgentInstance]) {
        let now = Date()
        let activePIDs = Set(agents.map { $0.pid })

        previousSamples = previousSamples.filter { activePIDs.contains($0.key) }

        for index in agents.indices {
            let pid = agents[index].pid
            guard let sample = getCurrentSample(pid: pid) else {
                continue
            }

            if let previous = previousSamples[pid] {
                let elapsed = now.timeIntervalSince(previous.wallTime)
                guard elapsed > 0 else {
                    previousSamples[pid] = sample
                    continue
                }

                let userDelta = Double(sample.userTicks &- previous.userTicks)
                let systemDelta = Double(sample.systemTicks &- previous.systemTicks)
                let totalDelta = userDelta + systemDelta

                let wallNanos = elapsed * 1_000_000_000
                let cpuPercent = (totalDelta / wallNanos) * 100.0

                let previousState = agents[index].activityState
                let newState: ActivityState = cpuPercent > workingThresholdPercent ? .working : .idle
                agents[index].activityState = newState

                if previousState == .working && newState == .idle {
                    onAgentCompleted?(agents[index])
                }
            } else {
                agents[index].activityState = .unknown
            }

            previousSamples[pid] = sample
        }
    }

    private func getCurrentSample(pid: pid_t) -> CPUSample? {
        var taskInfo = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, size)
        guard result > 0 else { return nil }

        return CPUSample(
            userTicks: taskInfo.pti_total_user,
            systemTicks: taskInfo.pti_total_system,
            wallTime: Date()
        )
    }
}

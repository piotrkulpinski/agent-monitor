import Foundation
import Combine
import OSLog

@MainActor
final class AgentMonitorService: ObservableObject {
    @Published var agents: [AgentInstance] = []

    var onAgentCompleted: ((AgentInstance) -> Void)?

    private let detectors: [any AgentDetector]
    private let activityMonitor = ActivityMonitor()
    private var monitoringTask: Task<Void, Never>?
    private let log = Logger(subsystem: "dev.piotrkulpinski.AgentMonitor", category: "monitor")

    init(detectors: [any AgentDetector] = []) {
        self.detectors = detectors
        activityMonitor.onAgentCompleted = { [weak self] agent in
            self?.onAgentCompleted?(agent)
        }
    }

    func startMonitoring() {
        log.info("startMonitoring called")
        monitoringTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    private func refresh() async {
        var allAgents: [AgentInstance] = []
        for detector in detectors {
            let detected = await detector.detect()
            allAgents.append(contentsOf: detected)
        }

        // Carry over previous activityState so ActivityMonitor can detect working→idle transitions.
        // Without this, allAgents always has .unknown (freshly created), so the transition never fires.
        let previousStates: [pid_t: ActivityState] = Dictionary(
            agents.map { ($0.pid, $0.activityState) },
            uniquingKeysWith: { first, _ in first }
        )
        for index in allAgents.indices {
            if let prev = previousStates[allAgents[index].pid] {
                allAgents[index].activityState = prev
            }
        }

        activityMonitor.updateActivityStates(for: &allAgents)

        // Detect working-start transitions for debounce tracking
        for agent in allAgents where agent.activityState == .working {
            let prev = previousStates[agent.pid]
            if prev == .idle || prev == .unknown || prev == nil {
                log.debug("agentStartedWorking: pid=\(agent.pid) prev=\(String(describing: prev))")
                NotificationService.shared.agentStartedWorking(agent)
            }
        }

        // Deduplicate: if multiple processes share the same (agentType, workingDirectory),
        // keep only the one with the highest PID (most recently started).
        let deduped = Dictionary(
            grouping: allAgents,
            by: { "\($0.agentType)-\($0.workingDirectory)" }
        ).values.map { group in
            group.max(by: { $0.pid < $1.pid })!
        }
        agents = deduped.sorted { $0.pid < $1.pid }
    }
}

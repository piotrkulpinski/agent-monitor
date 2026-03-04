import Foundation
import Combine

@MainActor
final class AgentMonitorService: ObservableObject {
    @Published var agents: [AgentInstance] = []

    var onAgentCompleted: ((AgentInstance) -> Void)?

    private let detectors: [any AgentDetector]
    private let activityMonitor = ActivityMonitor()
    private var monitoringTask: Task<Void, Never>?

    init(detectors: [any AgentDetector] = []) {
        self.detectors = detectors
        activityMonitor.onAgentCompleted = { [weak self] agent in
            self?.onAgentCompleted?(agent)
        }
    }

    func startMonitoring() {
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

        // Snapshot previous states before update
        let previousStates: [pid_t: ActivityState] = Dictionary(
            agents.map { ($0.pid, $0.activityState) },
            uniquingKeysWith: { first, _ in first }
        )

        activityMonitor.updateActivityStates(for: &allAgents)

        // Detect working-start transitions for debounce tracking
        for agent in allAgents where agent.activityState == .working {
            let prev = previousStates[agent.pid]
            if prev == .idle || prev == .unknown || prev == nil {
                NotificationService.shared.agentStartedWorking(agent)
            }
        }

        agents = allAgents
    }
}

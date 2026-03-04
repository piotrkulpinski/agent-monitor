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
        activityMonitor.updateActivityStates(for: &allAgents)
        agents = allAgents
    }
}

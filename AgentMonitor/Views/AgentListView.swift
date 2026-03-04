import SwiftUI
import ServiceManagement

struct AgentListView: View {
    @EnvironmentObject var monitorService: AgentMonitorService
    @EnvironmentObject var menuBarManager: MenuBarManager

    var claudeAgents: [AgentInstance] {
        monitorService.agents.filter { $0.agentType == .claudeCode }
            .sorted { $0.lastActiveTime > $1.lastActiveTime }
    }
    var openCodeAgents: [AgentInstance] {
        monitorService.agents.filter { $0.agentType == .openCode }
            .sorted { $0.lastActiveTime > $1.lastActiveTime }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AgentMonitor")
                    .font(.headline)
                Spacer()
                Text("\(monitorService.agents.count) agent\(monitorService.agents.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if monitorService.agents.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        if !claudeAgents.isEmpty {
                            Section {
                                ForEach(claudeAgents) { agent in
                                    AgentRowView(agent: agent)
                                    if agent.id != claudeAgents.last?.id {
                                        Divider().padding(.leading, 36)
                                    }
                                }
                            } header: {
                                SectionHeader(title: "Claude Code")
                            }
                        }
                        if !openCodeAgents.isEmpty {
                            Section {
                                ForEach(openCodeAgents) { agent in
                                    AgentRowView(agent: agent)
                                    if agent.id != openCodeAgents.last?.id {
                                        Divider().padding(.leading, 36)
                                    }
                                }
                            } header: {
                                SectionHeader(title: "Open Code")
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }

            Divider()
            HStack {
                Toggle("Launch at Login", isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Launch at login error: \(error)")
                        }
                    }
                ))
                .toggleStyle(.checkbox)
                .font(.caption)
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.regularMaterial)
    }
}

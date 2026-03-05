import SwiftUI

struct AgentRowView: View {
    let agent: AgentInstance
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StatusDot(state: agent.activityState)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(agent.displayTitle)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    DurationLabel(date: agent.lastActiveTime)
                }

                Text(agent.shortWorkingDirectory)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let model = agent.modelName {
                    Text(model)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Unknown model")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            FocusTerminalService.shared.focus(agent: agent)
        }
    }
}

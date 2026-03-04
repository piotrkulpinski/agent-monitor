import SwiftUI
import AppKit

@MainActor
final class MenuBarManager: ObservableObject {
    @Published var iconState: MenuBarIconState = .inactive
    @Published var currentImageName: String = MenuBarIconState.inactive.systemImageName

    private var animationTimer: Timer?
    private var isAnimationToggled = false

    func update(from agents: [AgentInstance]) {
        let newState: MenuBarIconState
        if agents.isEmpty {
            newState = .inactive
        } else if agents.contains(where: { $0.activityState == .working }) {
            newState = .active
        } else {
            newState = .idle
        }

        if newState != iconState {
            iconState = newState
            updateAnimation()
        }
    }

    private func updateAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isAnimationToggled = false

        if iconState == .active {
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isAnimationToggled.toggle()
                    self.currentImageName = self.isAnimationToggled
                        ? self.iconState.alternateSystemImageName
                        : self.iconState.systemImageName
                }
            }
        } else {
            currentImageName = iconState.systemImageName
        }
    }

    deinit {
        animationTimer?.invalidate()
    }
}

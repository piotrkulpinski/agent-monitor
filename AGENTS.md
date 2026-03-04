# AgentMonitor

A native macOS menu bar application that monitors running AI coding agents (Claude Code + Open Code), showing real-time status, project paths, model names, and session duration.

## Quick Start

```bash
# Build (Debug)
xcodebuild -scheme AgentMonitor -configuration Debug build

# Run
open ~/Sites/agent-monitor/build/Debug/AgentMonitor.app

# Build Release + DMG (after Makefile added in T13)
make build && make dmg
```

## Architecture

- **Entry point**: `AgentMonitor/AgentMonitorApp.swift` — `@main` SwiftUI App struct
- **UI style**: `MenuBarExtra` with `.window` style (floating panel, not inline menu)
- **No Dock icon**: `LSUIElement = true` in Info.plist
- **Bundle ID**: `dev.piotrkulpinski.AgentMonitor`
- **Deployment target**: macOS 14.0 (Sonoma) — required for MenuBarExtra
- **Code signing**: Ad-hoc (`CODE_SIGN_IDENTITY = "-"`) — no Apple Developer Program needed

## Modules

(Filled as tasks complete)

- `AgentDetector` protocol — T2
- `AgentType` enum — T2
- `ActivityState` enum — T2
- `AgentInstance` struct — T2
- `AgentMonitorService` class — T2

### Core Models (T2)
- `AgentMonitor/Models/AgentInstance.swift` — main data model: pid, workingDirectory, projectName (computed), modelName?, contextWindowUsage?, sessionStartTime, activityState
- `AgentMonitor/Models/AgentType.swift` — enum: .claudeCode, .openCode
- `AgentMonitor/Models/ActivityState.swift` — enum: .working, .idle, .unknown
- `AgentMonitor/Protocols/AgentDetector.swift` — protocol: agentType + detect() async -> [AgentInstance]
- `AgentMonitor/Services/AgentMonitorService.swift` — ObservableObject, @Published agents, startMonitoring/stopMonitoring, 3s polling loop
- `ClaudeCodeDetector` — T4
- `OpenCodeDetector` — T5
- `ActivityMonitor` — T6
- `ProcessTreeResolver` — T7
- Agent list popover UI — T8
- `FocusTerminalService` — T9
- `NotificationService` — T10
- Onboarding flow — T11

## Build & Run

```bash
# Verify Xcode
xcode-select -p  # /Applications/Xcode.app/Contents/Developer

# Debug build
xcodebuild -scheme AgentMonitor -configuration Debug build

# Release build
xcodebuild -scheme AgentMonitor -configuration Release build

# Run tests
xcodebuild test -scheme AgentMonitor -destination 'platform=macOS'
```

## Conventions

- Swift 5.9+, SwiftUI for all UI
- No third-party dependencies — pure Swift + system frameworks only
- No App Sandbox (required for process monitoring via libproc)
- Ad-hoc code signing (`CODE_SIGN_IDENTITY = "-"`) for local builds
- Template images for menu bar icons (`isTemplate = true`) for dark/light mode
- Polling: 3s process detection, 5s data enrichment (hardcoded, no settings UI)
- Protocol-based: new agents = new `AgentDetector` conforming type

## Gotchas

- **Process state R/S unreliable** for activity detection — all Claude instances show `S+` even when active. Use CPU delta over 3s window instead.
- **Working directory NOT in command-line args** — use `proc_pidinfo(PROC_PIDVNODEPATHINFO)` via libproc
- **Window names nil** via `CGWindowListCopyWindowInfo` for Ghostty/Terminal.app — Accessibility API required for window targeting
- **Open Code daemons** (PPID=1) have no terminal — mark `canFocusTerminal = false`
- **SQLite**: Open Code DB at `~/.local/share/opencode/opencode.db` — open with `SQLITE_OPEN_READONLY`, short-lived connections only

## Dependencies

No third-party dependencies. System frameworks:
- `SwiftUI` — UI
- `AppKit` — NSStatusItem, NSRunningApplication
- `Darwin` / libproc — process enumeration and info
- `SQLite3` — Open Code database reads (built into macOS SDK)
- `UserNotifications` — completion notifications
- `ApplicationServices` — Accessibility API for focus-terminal
- `ServiceManagement` — launch-at-login (SMAppService)

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
### Menu Bar Icon Management (T3)
- `AgentMonitor/Models/MenuBarIconState.swift` — enum: .inactive (circle.dashed), .idle (circle.fill), .active (circle.fill + animation)
- `AgentMonitor/UI/MenuBarManager.swift` — @MainActor ObservableObject, update(from:) computes state from agents, Timer-based 0.5s animation for active state
- SF Symbols used as template images (automatic dark/light mode in MenuBarExtra context)
- Active state: alternates between circle.fill and circle.dotted every 0.5s
- `ClaudeCodeDetector` — T4
- `OpenCodeDetector` — T5
- `ActivityMonitor` — T6
- `ProcessTreeResolver` — T7
- Agent list popover UI — T8
- `FocusTerminalService` — T9
- `NotificationService` — T10
- Onboarding flow — T11

### Process Tree Resolver (T7)
- `AgentMonitor/Core/ProcessTreeResolver.swift` — walks PPID chain from agent PID to terminal app
- `AgentMonitor/Models/ProcessTreeInfo.swift` — result: terminalPID?, terminalAppName?, canFocusTerminal
- Terminal apps detected: Ghostty, Terminal, iTerm2, kitty, Warp, WezTerm, Alacritty, rio
- Max depth: 10 levels (prevents infinite loops)
- Daemon detection: PPID=0 or PPID=1 → canFocusTerminal=false
- Uses proc_pidinfo(PROC_PIDTBSDINFO) → proc_bsdinfo.pbi_ppid for parent PID

### Open Code Detector (T5)
- `AgentMonitor/Detectors/OpenCodeDetector.swift` — finds processes named ".opencode" via proc_listallpids + proc_name
- CWD: same proc_pidinfo(PROC_PIDVNODEPATHINFO) approach as ClaudeCodeDetector
- SQLite: opens `~/.local/share/opencode/opencode.db` with SQLITE_OPEN_READONLY, PRAGMA query_only=ON
- Model name: queried from `session` + `message` tables, matched by working directory
- Graceful fallback: if DB missing or query fails, returns instances without modelName
- Short-lived connections: open -> query -> close each poll cycle (no persistent connection)
- Actual schema: `session.directory`, `message.session_id`, model in `json_extract(message.data, '$.modelID')`

### Claude Code Detector (T4)
- `AgentMonitor/Detectors/ClaudeCodeDetector.swift` — finds processes named "claude" via proc_listallpids + proc_name
- CWD: proc_pidinfo(PROC_PIDVNODEPATHINFO) → proc_vnodepathinfo.pvi_cdir.vip_path
- Start time: proc_pidinfo(PROC_PIDTBSDINFO) → proc_bsdinfo.pbi_start_tvsec + pbi_start_tvusec
- Handles stale PIDs gracefully (proc_pidinfo returns <= 0 for dead processes)
- Does NOT detect activity state (that's ActivityMonitor T6)

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

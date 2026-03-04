# AgentMonitor

> Monitor your AI coding agents from the macOS menu bar.

AgentMonitor is a native macOS menu bar application that detects and monitors running AI coding agents (Claude Code and Open Code), showing real-time status, project paths, model names, and session duration.

## Features

- **Real-time detection** — Automatically finds running Claude Code and Open Code processes
- **Activity monitoring** — Shows working/idle status via CPU delta heuristic (updates every 3 seconds)
- **Agent details** — Project name, full path, model name, session duration per agent
- **Focus terminal** — Click any agent row to bring its terminal window to the foreground
- **Completion notifications** — macOS notification when an agent finishes work
- **First-launch onboarding** — Guides you through optional permission setup
- **Launch at Login** — Optional, configurable from the menu bar popover

## Supported Agents

| Agent | Detection | Model Name | Focus Terminal |
|-------|-----------|------------|----------------|
| [Claude Code](https://claude.ai/code) | ✅ | — | ✅ |
| [Open Code](https://opencode.ai) | ✅ | ✅ (from SQLite) | ✅ |

Architecture is extensible — new agents can be added by conforming to the `AgentDetector` protocol.

## Installation

### Option A: Download DMG (easiest)

1. Download `AgentMonitor.dmg` from [Releases](https://github.com/piotrkulpinski/agent-monitor/releases)
2. Open the DMG and drag AgentMonitor to Applications
3. Right-click AgentMonitor.app → Open (required once to bypass Gatekeeper for unsigned apps)

### Option B: Build from Source

Requirements: macOS 14.0+, Xcode 15+

```bash
git clone https://github.com/piotrkulpinski/agent-monitor.git
cd agent-monitor
make build
make run
```

## Permissions

AgentMonitor requests two optional permissions:

- **Notifications** — To alert you when an agent finishes work. The app works without this.
- **Accessibility** — To focus the exact terminal window of an agent (not just the terminal app). The app works without this — clicking an agent row will still bring the terminal app to the foreground.

## Architecture

- **Protocol-based detectors** — `AgentDetector` protocol; each agent type is a separate conforming type
- **Process detection** — `libproc` C API for process enumeration and CWD extraction
- **Activity monitoring** — CPU delta heuristic: sampled every 3 seconds; >0.5% CPU = working
- **Open Code enrichment** — SQLite read from `~/.local/share/opencode/opencode.db` for model name
- **Process tree** — PPID chain walk to identify parent terminal app (Ghostty, Terminal, iTerm2, etc.)
- **Focus terminal** — `NSRunningApplication.activate()` + optional `AXUIElement` window raise

## Building for Distribution

```bash
make build   # Release build
make run     # Build + launch
make dmg     # Create AgentMonitor.dmg
make release # Instructions for notarized public distribution
```

## License

MIT — see [LICENSE](LICENSE)

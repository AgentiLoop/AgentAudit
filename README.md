# AgentAudit

Lightweight audit logging framework for macOS apps. Writes to `os.log` (visible in Console.app) with an in-memory ring buffer for programmatic access. Thread-safe, zero-config, no setup required.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AgentiLoop/AgentAudit.git", from: "1.3.6"),
]
```

Then add `"AgentAudit"` to your target's dependencies.

## Usage

```swift
import AgentAudit

// Log an event by category
AuditLog.log(.accessibility, "clickAt(x: 100, y: 200)")
AuditLog.log(.launchAgent, "execute: git status")
AuditLog.log(.appleScript, "execute: tell application \"Music\" to play")
AuditLog.log(.agentScript, "run: ArchiveXcode")
AuditLog.log(.xcode, "build: /path/to/project.xcodeproj")
AuditLog.log(.shell, "cd /Users/todd/project && swift build")
AuditLog.log(.mcp, "connect: filesystem-server")
AuditLog.log(.web, "navigate: https://example.com")

// Log permission requests with outcome
AuditLog.permission("Accessibility", granted: true)
AuditLog.permission("Screen Recording", granted: false)

// Log denied operations
AuditLog.denied(.launchDaemon, "execute blocked: rm -rf /")

// Retrieve recent entries programmatically
let entries = AuditLog.recentEntries(limit: 50)
```

## Categories

| Category | What it tracks |
|---|---|
| `.launchAgent` | Commands run via the Launch Agent (user-level XPC) |
| `.launchDaemon` | Commands run via the Launch Daemon (root-level XPC) |
| `.accessibility` | UI automation via the Accessibility API |
| `.appleScript` | AppleScript and osascript execution |
| `.agentScript` | Agent script creation, deletion, and execution |
| `.permission` | macOS permission requests and their outcomes |
| `.web` | Browser automation and web navigation |
| `.mcp` | MCP server connections and tool calls |
| `.xcode` | Xcode project builds and runs |
| `.shell` | Shell command execution |

## Viewing Logs

Open **Console.app** and filter by:
- **Subsystem**: `Agent.app.toddbruss.audit`
- **Category**: Any category name (e.g. `Accessibility`, `LaunchDaemon`)

## Design

- **os.log** for system-level persistence and Console.app integration
- **In-memory ring buffer** (last 1000 entries) for programmatic access
- **Thread-safe** via NSLock -- safe to call from any thread or actor
- **Zero overhead** when not actively reading logs (os.log is lazy)
- **Public privacy** -- audit messages are not redacted in release builds

## Requirements

- macOS 26 (Tahoe) or later
- Swift 6.2+

## License

MIT

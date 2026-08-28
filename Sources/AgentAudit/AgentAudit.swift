import os
import Foundation

/// Lightweight audit logger for Agent! — writes to os.log (visible in Console.app).
/// Categories map to security-relevant subsystems. All methods are nonisolated and thread-safe.
public enum AuditLog {

    // MARK: - Categories

    public enum Category: String, CaseIterable {
        case launchAgent    = "LaunchAgent"
        case launchDaemon   = "LaunchDaemon"
        case accessibility  = "Accessibility"
        case appleScript    = "AppleScript"
        case agentScript    = "AgentScript"
        case permission     = "Permission"
        case web            = "Web"
        case mcp            = "MCP"
        case xcode          = "Xcode"
        case shell          = "Shell"
        case fileBackup     = "FileBackup"
        case storage        = "Storage"
        case keychain       = "Keychain"
        case api            = "API"
        case tool           = "Tool"
        case disk           = "Disk"
    }

    // MARK: - Loggers (one per category for efficient filtering)

    private static let subsystem = "Agent.app.toddbruss.audit"

    nonisolated(unsafe) private static let loggers: [Category: Logger] = {
        // Built from allCases — the old hand-maintained list crashed on the
        // force-unwrap below whenever a new category was forgotten here.
        var map: [Category: Logger] = [:]
        for cat in Category.allCases {
            map[cat] = Logger(subsystem: subsystem, category: cat.rawValue)
        }
        return map
    }()

    // MARK: - In-Memory Ring Buffer (for ax_get_audit_log tool)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var ringBuffer: [String] = []
    private static let maxEntries = 1000

    /// ISO8601DateFormatter is documented thread-safe — allocate once, not per log call.
    nonisolated(unsafe) private static let timestampFormatter = ISO8601DateFormatter()

    private nonisolated static func appendToBuffer(_ category: Category, _ message: String) {
        let timestamp = timestampFormatter.string(from: Date())
        let entry = "[\(timestamp)] [\(category.rawValue)] \(message)"
        lock.lock()
        ringBuffer.append(entry)
        if ringBuffer.count > maxEntries {
            ringBuffer.removeFirst(ringBuffer.count - maxEntries + 99)
        }
        lock.unlock()
    }

    // MARK: - Public API

    /// Log an audit event. Writes to os.log and in-memory ring buffer.
    public nonisolated static func log(_ category: Category, _ message: String) {
        if let logger = loggers[category] {
            logger.info("\(message, privacy: .public)")
        }
        appendToBuffer(category, message)
    }

    /// Log a permission request and its outcome.
    public nonisolated static func permission(_ what: String, granted: Bool) {
        let status = granted ? "GRANTED" : "DENIED"
        log(.permission, "\(what): \(status)")
    }

    /// Log a denied/failed operation.
    public nonisolated static func denied(_ category: Category, _ message: String) {
        if let logger = loggers[category] {
            logger.warning("\(message, privacy: .public)")
        }
        appendToBuffer(category, "DENIED: \(message)")
    }

    /// Retrieve recent audit entries (for the ax_get_audit_log tool).
    public nonisolated static func recentEntries(limit: Int = 50) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(ringBuffer.suffix(limit))
    }
}


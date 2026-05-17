import Foundation
import os

enum Log {
    private static let subsystem = "app.clippa.Clippa"
    static let app = OSLog(subsystem: subsystem, category: "app")
    static let clipboard = OSLog(subsystem: subsystem, category: "clipboard")
    static let db = OSLog(subsystem: subsystem, category: "db")
    static let ui = OSLog(subsystem: subsystem, category: "ui")

    static func info(_ message: String, _ log: OSLog = app) {
        os_log("%{public}@", log: log, type: .info, message)
    }

    static func error(_ message: String, _ log: OSLog = app) {
        os_log("%{public}@", log: log, type: .error, message)
    }

    static func debug(_ message: String, _ log: OSLog = app) {
        os_log("%{public}@", log: log, type: .debug, message)
    }
}

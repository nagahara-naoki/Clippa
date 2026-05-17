import Foundation

enum AppPaths {
    static let appName = "Clippa"

    static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(appName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var databaseURL: URL {
        supportDirectory.appendingPathComponent("clippa.sqlite")
    }

    static var imagesDirectory: URL {
        let dir = supportDirectory.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var thumbnailsDirectory: URL {
        let dir = supportDirectory.appendingPathComponent("thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var logFileURL: URL {
        supportDirectory.appendingPathComponent("clippa.log")
    }
}

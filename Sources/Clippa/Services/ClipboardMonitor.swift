import Foundation
import AppKit
import CryptoKit
import UniformTypeIdentifiers

final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    private var changeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    private var screenshotTimer: Timer?
    private var seenScreenshotPaths: Set<String> = []
    private var screenshotWatchStartedAt = Date()
    private let pollInterval: TimeInterval = 0.4
    private let screenshotPollInterval: TimeInterval = 1.0

    private let store = ClipboardStore.shared
    private let prefs = PreferencesStore.shared

    /// 自身が貼り付け目的でクリップボードへ書き込んだ際の changeCount を保持し、
    /// その値の変化を「ユーザーが新しくコピーした」と誤検出しないために使う。
    private(set) var ignoreChangeCount: Int = -1

    private init() {}

    func start() {
        guard timer == nil else { return }
        changeCount = NSPasteboard.general.changeCount
        screenshotWatchStartedAt = Date().addingTimeInterval(-2)
        let t = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
        let screenshots = Timer(timeInterval: screenshotPollInterval, repeats: true) { [weak self] _ in
            self?.pollScreenshotFiles()
        }
        RunLoop.main.add(screenshots, forMode: .common)
        self.screenshotTimer = screenshots
        Log.info("clipboard monitor started", Log.clipboard)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        screenshotTimer?.invalidate()
        screenshotTimer = nil
    }

    func markIgnore(changeCount: Int) {
        self.ignoreChangeCount = changeCount
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != changeCount else { return }
        changeCount = pb.changeCount

        if pb.changeCount == ignoreChangeCount { return }

        // Concealed / Transient はスキップ（パスワードマネージャ等）
        if let types = pb.types {
            for t in types {
                let s = t.rawValue.lowercased()
                if s.contains("concealed") || s.contains("transient") {
                    return
                }
            }
        }

        // 除外アプリ
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bid = frontApp.bundleIdentifier,
           prefs.excludedBundleIDs.contains(bid) {
            return
        }

        guard let item = makeItem(from: pb) else { return }

        // 重複検出: ハッシュ一致 → 既存を先頭へ移動
        if let existing = store.find(byHash: item.contentHash) {
            store.touchToTop(id: existing.id)
            return
        }
        store.insert(item)
    }

    private func makeItem(from pb: NSPasteboard) -> ClipItem? {
        let frontApp = NSWorkspace.shared.frontmostApplication
        let sourceApp = frontApp?.localizedName
        let sourceBundle = frontApp?.bundleIdentifier

        if let nsImage = image(from: pb),
           let pngData = pngData(from: nsImage, fallback: nil) {
            return makeImageItem(pngData: pngData, size: nsImage.size, sourceApp: sourceApp, sourceBundle: sourceBundle)
        }

        // ファイル URL
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            let joined = urls.map { $0.path }.joined(separator: "\n")
            let hash = sha256(Data(joined.utf8))
            return ClipItem(
                kind: .fileURL,
                text: joined,
                sourceApp: sourceApp,
                sourceBundleID: sourceBundle,
                contentHash: hash
            )
        }

        // RTF / HTML を保持しつつ、表示用のプレーンテキストを抽出
        let rtf = pb.data(forType: .rtf)
        let html = pb.data(forType: .html)
        guard let plain = pb.string(forType: .string), !plain.isEmpty else { return nil }

        let kind: ClipKind = {
            if rtf != nil { return .richText }
            if html != nil { return .html }
            if isURL(plain) { return .url }
            return .plainText
        }()

        let hash = sha256(Data(plain.utf8))
        return ClipItem(
            kind: kind,
            text: plain,
            richTextData: rtf,
            htmlData: html,
            sourceApp: sourceApp,
            sourceBundleID: sourceBundle,
            contentHash: hash
        )
    }

    private func pollScreenshotFiles() {
        let fileManager = FileManager.default
        let directory = screenshotDirectory()
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let cutoff = Date().addingTimeInterval(-15)
        for url in contents where isScreenshotCandidate(url) {
            let path = url.path
            guard !seenScreenshotPaths.contains(path) else { continue }
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let modified = values.contentModificationDate,
                  modified >= screenshotWatchStartedAt,
                  modified >= cutoff else {
                continue
            }
            seenScreenshotPaths.insert(path)
            insertScreenshot(url: url)
        }
    }

    private func insertScreenshot(url: URL) {
        guard let image = NSImage(contentsOf: url),
              let pngData = pngData(from: image, fallback: try? Data(contentsOf: url)),
              let item = makeImageItem(pngData: pngData, size: image.size, sourceApp: "Screenshot", sourceBundle: nil) else {
            return
        }
        if let existing = store.find(byHash: item.contentHash) {
            store.touchToTop(id: existing.id)
            return
        }
        store.insert(item)
    }

    private func screenshotDirectory() -> URL {
        if let custom = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location"),
           !custom.isEmpty {
            let expanded = (custom as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded, isDirectory: true)
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop", isDirectory: true)
    }

    private func isScreenshotCandidate(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard ["png", "jpg", "jpeg", "heic", "tiff"].contains(ext) else { return false }
        let name = url.deletingPathExtension().lastPathComponent.lowercased()
        return name.hasPrefix("screenshot") || name.hasPrefix("screen shot") || name.hasPrefix("スクリーンショット")
    }

    private func makeImageItem(pngData: Data, size: NSSize, sourceApp: String?, sourceBundle: String?) -> ClipItem? {
        guard let stored = ImageStore.save(pngData: pngData, sourceSize: size) else { return nil }
        return ClipItem(
            kind: .image,
            imageFileName: stored.fileName,
            imageThumbnailPath: stored.thumbnailPath,
            imageWidth: stored.width,
            imageHeight: stored.height,
            imageBytes: stored.bytes,
            sourceApp: sourceApp,
            sourceBundleID: sourceBundle,
            contentHash: sha256(pngData)
        )
    }

    private func image(from pb: NSPasteboard) -> NSImage? {
        if let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let image = images.first {
            return image
        }

        guard let types = pb.types else { return nil }
        for type in types {
            guard let utType = UTType(type.rawValue), utType.conforms(to: .image) else { continue }
            guard let data = pb.data(forType: type), let image = NSImage(data: data) else { continue }
            return image
        }
        return nil
    }

    private func pngData(from image: NSImage, fallback: Data?) -> Data? {
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            return png
        }
        return fallback
    }

    private func isURL(_ s: String) -> Bool {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else { return false }
        return URL(string: trimmed) != nil
    }

    private func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

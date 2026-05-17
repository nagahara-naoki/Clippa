import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

enum ImageStore {
    static let maxImageBytesPerItem = 4 * 1024 * 1024
    static let thumbnailMaxSide: CGFloat = 200

    struct Stored {
        let fileName: String
        let thumbnailPath: String
        let width: Int
        let height: Int
        let bytes: Int
    }

    static func save(pngData: Data, sourceSize: NSSize) -> Stored? {
        guard pngData.count <= maxImageBytesPerItem else { return nil }
        let fileName = UUID().uuidString + ".png"
        let url = AppPaths.imagesDirectory.appendingPathComponent(fileName)
        do {
            try pngData.write(to: url, options: .atomic)
        } catch {
            Log.error("image save failed: \(error)")
            return nil
        }
        let thumbName = "thumb-" + fileName
        let thumbURL = AppPaths.thumbnailsDirectory.appendingPathComponent(thumbName)
        let thumbnailPath: String?
        if let thumb = makeThumbnail(pngData: pngData) {
            try? thumb.write(to: thumbURL, options: .atomic)
            thumbnailPath = thumbURL.path
        } else {
            thumbnailPath = nil
        }
        return Stored(
            fileName: fileName,
            thumbnailPath: thumbnailPath ?? "",
            width: Int(sourceSize.width),
            height: Int(sourceSize.height),
            bytes: pngData.count
        )
    }

    static func loadImage(fileName: String) -> NSImage? {
        let url = AppPaths.imagesDirectory.appendingPathComponent(fileName)
        return NSImage(contentsOf: url)
    }

    static func loadThumbnail(path: String) -> NSImage? {
        guard !path.isEmpty else { return nil }
        return NSImage(contentsOfFile: path)
    }

    static func delete(fileName: String, thumbnailPath: String?) {
        let url = AppPaths.imagesDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        if let thumbnailPath {
            try? FileManager.default.removeItem(atPath: thumbnailPath)
        }
    }

    private static func makeThumbnail(pngData: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(pngData as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(thumbnailMaxSide)
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let data = NSMutableData() as CFMutableData?,
              let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, thumbnail, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}

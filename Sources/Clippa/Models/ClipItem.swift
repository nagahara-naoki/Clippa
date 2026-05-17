import Foundation
import AppKit

struct ClipItem: Identifiable, Hashable {
    let id: UUID
    var kind: ClipKind
    var text: String?
    var richTextData: Data?
    var htmlData: Data?
    var imageFileName: String?
    var imageThumbnailPath: String?
    var imageWidth: Int?
    var imageHeight: Int?
    var imageBytes: Int?
    var sourceApp: String?
    var sourceBundleID: String?
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var contentHash: String

    init(
        id: UUID = UUID(),
        kind: ClipKind,
        text: String? = nil,
        richTextData: Data? = nil,
        htmlData: Data? = nil,
        imageFileName: String? = nil,
        imageThumbnailPath: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageBytes: Int? = nil,
        sourceApp: String? = nil,
        sourceBundleID: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        contentHash: String
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.richTextData = richTextData
        self.htmlData = htmlData
        self.imageFileName = imageFileName
        self.imageThumbnailPath = imageThumbnailPath
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageBytes = imageBytes
        self.sourceApp = sourceApp
        self.sourceBundleID = sourceBundleID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.contentHash = contentHash
    }

    var previewText: String {
        switch kind {
        case .plainText, .richText, .html, .url:
            let raw = text ?? ""
            let single = raw.replacingOccurrences(of: "\n", with: " ")
            return single.count > 120 ? String(single.prefix(120)) + "…" : single
        case .image:
            if let w = imageWidth, let h = imageHeight {
                return "Image \(w)x\(h)"
            }
            return "Image"
        case .fileURL:
            return text ?? "File"
        case .color:
            return text ?? "Color"
        }
    }
}

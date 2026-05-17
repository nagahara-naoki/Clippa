import Foundation

enum ClipKind: String, Codable, CaseIterable {
    case plainText
    case richText
    case html
    case image
    case fileURL
    case url
    case color

    var isImage: Bool { self == .image }
}

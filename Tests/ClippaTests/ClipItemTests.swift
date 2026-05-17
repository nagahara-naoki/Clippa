import XCTest
@testable import Clippa

final class ClipItemTests: XCTestCase {
    func testPreviewTextTruncates() {
        let long = String(repeating: "a", count: 200)
        let item = ClipItem(kind: .plainText, text: long, contentHash: "x")
        XCTAssertLessThanOrEqual(item.previewText.count, 121)
        XCTAssertTrue(item.previewText.hasSuffix("…"))
    }

    func testPreviewTextSingleLine() {
        let item = ClipItem(kind: .plainText, text: "a\nb\nc", contentHash: "x")
        XCTAssertFalse(item.previewText.contains("\n"))
    }

    func testImagePreviewShowsDimensions() {
        let item = ClipItem(
            kind: .image,
            imageWidth: 1280,
            imageHeight: 720,
            contentHash: "x"
        )
        XCTAssertEqual(item.previewText, "Image 1280x720")
    }
}

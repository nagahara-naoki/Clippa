import XCTest
@testable import Clippa

final class SnippetEngineTests: XCTestCase {
    func testPlainText() {
        let r = SnippetEngine.expand("hello", clipboard: nil)
        XCTAssertEqual(r.text, "hello")
        XCTAssertNil(r.cursorOffset)
    }

    func testDateExpansion() {
        let r = SnippetEngine.expand("today is {date}")
        XCTAssertTrue(r.text.hasPrefix("today is "))
        XCTAssertTrue(r.text.count > "today is ".count)
    }

    func testCustomFormat() {
        let r = SnippetEngine.expand("{date:yyyy}")
        XCTAssertEqual(r.text.count, 4)
    }

    func testClipboardSubstitution() {
        let r = SnippetEngine.expand("re: {clipboard}", clipboard: "hi")
        XCTAssertEqual(r.text, "re: hi")
    }

    func testCursorOffset() {
        let r = SnippetEngine.expand("a{cursor}b")
        XCTAssertEqual(r.text, "ab")
        XCTAssertEqual(r.cursorOffset, 1)
    }

    func testUnknownTokenLeftUnchanged() {
        let r = SnippetEngine.expand("hi {unknown}")
        XCTAssertEqual(r.text, "hi {unknown}")
    }
}

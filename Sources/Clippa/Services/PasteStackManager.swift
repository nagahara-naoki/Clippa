import Foundation
import Combine
import AppKit

/// ペーストスタック機能。
/// 有効時、ポップアップで複数の項目を選択して「キュー」に積み、
/// Cmd+V を押すたびに先頭から順に貼り付ける。
final class PasteStackManager: ObservableObject {
    static let shared = PasteStackManager()

    @Published private(set) var queue: [ClipItem] = []

    private let prefs = PreferencesStore.shared

    private init() {}

    var isEnabled: Bool { prefs.pasteStackEnabled }

    func enqueue(_ item: ClipItem) {
        queue.append(item)
    }

    func enqueueMany(_ items: [ClipItem]) {
        queue.append(contentsOf: items)
    }

    func clear() {
        queue.removeAll()
    }

    /// 次の項目を取り出して貼り付ける。スタックが空なら何もしない。
    /// 戻り値は「次の貼付が成功したか」。
    @discardableResult
    func pasteNext() -> Bool {
        guard !queue.isEmpty else { return false }
        let next = queue.removeFirst()
        PasteEngine.writeAndPaste(next)
        return true
    }
}

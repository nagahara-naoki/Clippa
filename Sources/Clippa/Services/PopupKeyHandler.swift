import Foundation
import Combine

/// ポップアップ内のキー入力を子ビュー（History/Snippet タブ）に伝搬するための調停役。
/// PopupContentView が NSEvent を購読し、ここに publish する。
/// HistoryListView / SnippetListView が監視して反応する。
final class PopupKeyHandler: ObservableObject {
    /// 1〜9 の数字キーが押された (Cmd / Ctrl 修飾なし)
    let digitPressed = PassthroughSubject<Int, Never>()
    /// Space キーが押された (プレビューのトグル)
    let spacePressed = PassthroughSubject<Void, Never>()
    /// ↑↓ 矢印キーが押された (-1 / +1)
    let arrowPressed = PassthroughSubject<Int, Never>()
    /// Return キーが押された (選択中項目を貼り付け)
    let returnPressed = PassthroughSubject<Void, Never>()
}

import Foundation
import Combine
import SwiftUI

/// 言語切替の中央管理。
///
/// アプリ内で SystemLocale / "ja" / "en" を切り替えられるようにする。
/// `Localizer.shared.string("key")` を使うと、現在の選択言語に対応する Bundle から
/// 翻訳を取得する。`languageChanged` がトリガーされると SwiftUI ビューが再描画される。
final class Localizer: ObservableObject {
    static let shared = Localizer()

    /// 現在ロード中の Bundle。"system" の場合は Bundle.main。
    @Published private(set) var bundle: Bundle = .main
    /// 表示中の言語コード ("ja" / "en")
    @Published private(set) var resolvedLanguage: String = "en"

    private init() {}

    /// "system" / "ja" / "en" を受け取り、対応 Bundle をロード。
    func apply(_ preferred: String) {
        let lang: String
        if preferred == "system" {
            lang = Bundle.main.preferredLocalizations.first ?? "en"
        } else {
            lang = preferred
        }

        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let b = Bundle(path: path) {
            self.bundle = b
        } else {
            self.bundle = .main
        }
        self.resolvedLanguage = lang.hasPrefix("ja") ? "ja" : "en"
    }

    /// Localized string lookup respecting the current preferred language.
    func string(_ key: String, comment: String = "") -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

/// 既存の NSLocalizedString 呼び出しを Localizer 経由に置き換えるためのショートハンド。
/// 既存コードの可読性を保つため、関数として用意。
func L(_ key: String) -> String {
    Localizer.shared.string(key)
}

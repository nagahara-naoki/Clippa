import Foundation
import AppKit

/// スニペットの変数展開エンジン。
/// 対応変数: {date} {date:fmt} {time} {datetime} {clipboard} {cursor}
enum SnippetEngine {
    struct ExpansionResult {
        let text: String
        /// 展開後の文字列内での {cursor} の位置（0-based UTF-16 offset）。なければ nil。
        let cursorOffset: Int?
    }

    static func expand(_ template: String, clipboard: String? = nil) -> ExpansionResult {
        var output = ""
        var cursorOffset: Int? = nil
        var i = template.startIndex
        let end = template.endIndex

        while i < end {
            if template[i] == "{",
               let closeIndex = template[i...].firstIndex(of: "}") {
                let tokenStart = template.index(after: i)
                let token = String(template[tokenStart..<closeIndex])
                if let replaced = resolve(token: token, clipboard: clipboard) {
                    if token == "cursor" {
                        cursorOffset = output.utf16.count
                    } else {
                        output.append(replaced)
                    }
                    i = template.index(after: closeIndex)
                    continue
                }
            }
            output.append(template[i])
            i = template.index(after: i)
        }
        return ExpansionResult(text: output, cursorOffset: cursorOffset)
    }

    private static func resolve(token: String, clipboard: String?) -> String? {
        let lower = token.lowercased()
        let now = Date()
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP_POSIX")
        df.timeZone = .current

        if lower == "date" {
            df.dateFormat = "yyyy-MM-dd"
            return df.string(from: now)
        }
        if lower == "time" {
            df.dateFormat = "HH:mm"
            return df.string(from: now)
        }
        if lower == "datetime" {
            df.dateFormat = "yyyy-MM-dd HH:mm"
            return df.string(from: now)
        }
        if lower.hasPrefix("date:") {
            let fmt = String(token.dropFirst(5))
            df.dateFormat = fmt
            return df.string(from: now)
        }
        if lower.hasPrefix("datetime:") {
            let fmt = String(token.dropFirst(9))
            df.dateFormat = fmt
            return df.string(from: now)
        }
        if lower == "clipboard" {
            return clipboard ?? ""
        }
        if lower == "cursor" {
            return ""
        }
        return nil
    }
}

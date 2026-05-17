import AppKit
import Carbon.HIToolbox

/// クリップボードへ書き戻し、前面アプリに `Cmd+V` を送ることで自動貼り付けする。
enum PasteEngine {
    static func writeAndPaste(_ item: ClipItem, completion: (() -> Void)? = nil) {
        writeToClipboard(item)
        // クリップボードを書き換えた直後の changeCount を「無視」マークして、
        // ClipboardMonitor がこれを新規コピーとして拾わないようにする。
        let cc = NSPasteboard.general.changeCount
        ClipboardMonitor.shared.markIgnore(changeCount: cc)
        pasteCurrentClipboard(completion: completion)
    }

    static func writeToClipboard(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.kind {
        case .image:
            if let fname = item.imageFileName,
               let img = ImageStore.loadImage(fileName: fname) {
                pb.writeObjects([img])
            }
        case .fileURL:
            if let paths = item.text?.split(separator: "\n").map(String.init) {
                let urls = paths.map { URL(fileURLWithPath: $0) as NSURL }
                pb.writeObjects(urls)
            }
        case .richText:
            if let rtf = item.richTextData {
                pb.setData(rtf, forType: .rtf)
            }
            if let t = item.text {
                pb.setString(t, forType: .string)
            }
        case .html:
            if let html = item.htmlData {
                pb.setData(html, forType: .html)
            }
            if let t = item.text {
                pb.setString(t, forType: .string)
            }
        case .plainText, .url, .color:
            if let t = item.text {
                pb.setString(t, forType: .string)
            }
        }
    }

    static func writeStringToClipboard(_ string: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
        ClipboardMonitor.shared.markIgnore(changeCount: pb.changeCount)
    }

    static func pasteCurrentClipboard(completion: (() -> Void)? = nil) {
        let restored = PopupWindowController.shared.reactivatePreviousApp()
        let delay = restored ? 0.18 : 0.08
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            sendCmdV()
            completion?()
        }
    }

    static func sendCmdV() {
        guard Permissions.isAccessibilityTrusted(promptIfNeeded: true) else {
            Log.error("Accessibility not granted; cannot send Cmd+V")
            return
        }
        let src = CGEventSource(stateID: .combinedSessionState)
        let vKey = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }
}

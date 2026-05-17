import SwiftUI

struct PopupContentView: View {
    enum Tab: Int, CaseIterable {
        case history
        case snippets
        var title: String {
            switch self {
            case .history: return NSLocalizedString("tab.history", comment: "")
            case .snippets: return NSLocalizedString("tab.snippets", comment: "")
            }
        }
    }

    @State private var selectedTab: Tab = .history
    @StateObject private var keyHandler = PopupKeyHandler()

    var body: some View {
        ZStack {
            VisualEffectBackground()
                .ignoresSafeArea()
            VStack(spacing: 0) {
                tabBar
                Divider().opacity(0.5)
                Group {
                    switch selectedTab {
                    case .history:
                        HistoryListView()
                            .environmentObject(keyHandler)
                    case .snippets:
                        SnippetListView()
                            .environmentObject(keyHandler)
                    }
                }
            }
        }
        .frame(width: 360, height: 500)
        .background(KeyEventCatcher { event in
            handleKey(event)
        })
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.title)
                        .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(selectedTab == tab ? Color.primary.opacity(0.09) : Color.clear)
                )
            }
        }
        .padding(8)
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        let isEditingText = event.window?.firstResponder is NSTextView

        // タブ切替: Cmd+1/2
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "1" {
                selectedTab = .history; return true
            } else if event.charactersIgnoringModifiers == "2" {
                selectedTab = .snippets; return true
            }
        }

        // Esc: パネルを閉じる
        if event.keyCode == 53 {
            PopupWindowController.shared.close()
            return true
        }

        // ↑↓ 矢印キー
        if event.keyCode == 126 {  // ↑
            keyHandler.arrowPressed.send(-1); return true
        }
        if event.keyCode == 125 {  // ↓
            keyHandler.arrowPressed.send(+1); return true
        }

        if !isEditingText && event.keyCode == 123 {  // ←
            selectedTab = .history
            return true
        }
        if !isEditingText && event.keyCode == 124 {  // →
            selectedTab = .snippets
            return true
        }

        // Return / Enter
        if event.keyCode == 36 || event.keyCode == 76 {
            keyHandler.returnPressed.send(); return true
        }

        // Space → プレビュー (テキスト入力中は除く)
        if event.keyCode == 49 && !event.modifierFlags.contains(.command) {
            if !isEditingText {
                keyHandler.spacePressed.send()
                return true
            }
        }

        // 数字キー 1〜9 (修飾キーなし)
        if let chars = event.charactersIgnoringModifiers,
           chars.count == 1,
           let digit = Int(chars),
           digit >= 1 && digit <= 9,
           !event.modifierFlags.contains(.command),
           !event.modifierFlags.contains(.option) {
            if !isEditingText {
                keyHandler.digitPressed.send(digit)
                return true
            }
        }
        return false
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .popover
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

/// SwiftUI 内でキーイベントを受けるためのフック。
struct KeyEventCatcher: NSViewRepresentable {
    let onKey: (NSEvent) -> Bool

    func makeNSView(context: Context) -> NSView {
        let v = CatcherView()
        v.onKey = onKey
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private class CatcherView: NSView {
        var onKey: ((NSEvent) -> Bool)?
        override var acceptsFirstResponder: Bool { true }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }
        override func keyDown(with event: NSEvent) {
            if onKey?(event) != true {
                super.keyDown(with: event)
            }
        }
    }
}

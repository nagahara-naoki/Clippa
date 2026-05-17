import AppKit
import SwiftUI

final class PopupWindowController: NSObject {
    static let shared = PopupWindowController()

    private var panel: NSPanel?
    private var previousFrontmostApp: NSRunningApplication?
    private let ownBundleIdentifier = Bundle.main.bundleIdentifier

    private override init() { super.init() }

    func toggle() {
        if let panel, panel.isVisible {
            close()
        } else {
            show()
        }
    }

    func present() {
        show()
    }

    func show() {
        if panel == nil {
            panel = makePanel()
        }
        guard let panel else { return }
        rememberPreviousAppIfNeeded()
        positionPanel(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    func close() {
        panel?.orderOut(nil)
    }

    @discardableResult
    func reactivatePreviousApp() -> Bool {
        guard let app = previousFrontmostApp else { return false }
        return app.activate(options: [.activateIgnoringOtherApps])
    }

    private func makePanel() -> NSPanel {
        let size = NSSize(width: 360, height: 500)
        let style: NSWindow.StyleMask = [.borderless, .nonactivatingPanel, .fullSizeContentView]
        let panel = PopupPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let content = PopupContentView()
            .environmentObject(ClipboardStore.shared)
            .environmentObject(SnippetStore.shared)
            .environmentObject(PasteStackManager.shared)
            .environmentObject(PreferencesStore.shared)

        let host = NSHostingView(rootView: content)
        host.frame = NSRect(origin: .zero, size: size)
        panel.contentView = host
        return panel
    }

    private func positionPanel(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let x = visible.midX - size.width / 2
        let y = visible.midY - size.height / 2 + 60
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func rememberPreviousAppIfNeeded() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        guard app.bundleIdentifier != ownBundleIdentifier else { return }
        previousFrontmostApp = app
    }
}

private final class PopupPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

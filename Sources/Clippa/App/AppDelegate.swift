import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBar = MenuBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.info("Clippa launching")

        // ストア類の初期化（lazy 初期化を確実にしておく）
        _ = ClipboardStore.shared
        _ = SnippetStore.shared
        _ = PreferencesStore.shared

        // メニューバー常駐
        menuBar.install()

        // クリップボード監視開始
        ClipboardMonitor.shared.start()

        // グローバルホットキー登録
        HotkeyManager.shared.onTrigger = {
            PopupWindowController.shared.present()
        }
        HotkeyManager.shared.register()

        // 初回オンボーディング
        menuBar.showOnboardingIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
        ClipboardMonitor.shared.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        PopupWindowController.shared.toggle()
        return true
    }
}

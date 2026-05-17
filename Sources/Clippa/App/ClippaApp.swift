import AppKit

@main
enum ClippaMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // Dock 非表示・メニューバーアプリ
        app.run()
    }
}

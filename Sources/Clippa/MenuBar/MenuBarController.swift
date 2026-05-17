import AppKit

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = makeStatusBarImage()
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.target = self
            button.action = #selector(buttonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = item
    }

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            guard let button = statusItem?.button else { return }
            let menu = buildMenu()
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button)
        } else {
            PopupWindowController.shared.toggle()
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let open = NSMenuItem(title: NSLocalizedString("menu.openPopup", comment: ""),
                              action: #selector(openPopup), keyEquivalent: "v")
        open.keyEquivalentModifierMask = [.command, .shift]
        open.target = self
        menu.addItem(open)

        menu.addItem(NSMenuItem.separator())

        let prefs = NSMenuItem(title: NSLocalizedString("menu.preferences", comment: ""),
                               action: #selector(openSettings), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        let about = NSMenuItem(title: NSLocalizedString("menu.about", comment: ""),
                               action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(title: NSLocalizedString("menu.quit", comment: ""),
                              action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        return menu
    }

    @objc private func openPopup() {
        PopupWindowController.shared.toggle()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let host = NSHostingControllerEnvironmentInjector.make {
                SettingsView()
            }
            let win = NSWindow(contentViewController: host)
            win.title = "Clippa Preferences"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.setContentSize(NSSize(width: 520, height: 420))
            win.center()
            settingsWindow = win
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    func showOnboardingIfNeeded() {
        guard !PreferencesStore.shared.onboardingCompleted else { return }
        let host = NSHostingControllerEnvironmentInjector.make {
            OnboardingView {
                PreferencesStore.shared.onboardingCompleted = true
                self.onboardingWindow?.close()
            }
        }
        let win = NSWindow(contentViewController: host)
        win.title = "Welcome"
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 460, height: 360))
        win.center()
        onboardingWindow = win
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    private func makeStatusBarImage() -> NSImage {
        if let asset = NSImage(named: "MenuBarIcon") {
            asset.size = NSSize(width: 18, height: 18)
            asset.isTemplate = true
            return asset
        }

        let fallback = NSImage(systemSymbolName: "archivebox", accessibilityDescription: "Clippa") ?? NSImage()
        fallback.isTemplate = true
        return fallback
    }
}

import SwiftUI

/// 環境オブジェクト注入を共通化する小さなヘルパ。
enum NSHostingControllerEnvironmentInjector {
    static func make<Content: View>(@ViewBuilder _ build: () -> Content) -> NSHostingController<some View> {
        let view = build()
            .environmentObject(ClipboardStore.shared)
            .environmentObject(SnippetStore.shared)
            .environmentObject(PasteStackManager.shared)
            .environmentObject(PreferencesStore.shared)
        return NSHostingController(rootView: view)
    }
}

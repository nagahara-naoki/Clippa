import AppKit
import ApplicationServices

enum Permissions {
    static func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityTrust() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options: CFDictionary = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

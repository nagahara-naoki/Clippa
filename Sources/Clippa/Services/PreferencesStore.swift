import Foundation
import Combine

final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let launchAtLogin = "launchAtLogin"
        static let showInMenuBar = "showInMenuBar"
        static let maxTextItems = "maxTextItems"
        static let maxRetentionDays = "maxRetentionDays"
        static let maxImageBytes = "maxImageBytes"
        static let maxImageItems = "maxImageItems"
        static let pasteStackEnabled = "pasteStackEnabled"
        static let onboardingCompleted = "onboardingCompleted"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let preferredLanguage = "preferredLanguage"
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Key.launchAtLogin) }
    }
    @Published var showInMenuBar: Bool {
        didSet { defaults.set(showInMenuBar, forKey: Key.showInMenuBar) }
    }
    @Published var maxTextItems: Int {
        didSet { defaults.set(maxTextItems, forKey: Key.maxTextItems) }
    }
    @Published var maxRetentionDays: Int {
        didSet { defaults.set(maxRetentionDays, forKey: Key.maxRetentionDays) }
    }
    @Published var maxImageBytes: Int {
        didSet { defaults.set(maxImageBytes, forKey: Key.maxImageBytes) }
    }
    @Published var maxImageItems: Int {
        didSet { defaults.set(maxImageItems, forKey: Key.maxImageItems) }
    }
    @Published var pasteStackEnabled: Bool {
        didSet { defaults.set(pasteStackEnabled, forKey: Key.pasteStackEnabled) }
    }
    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) }
    }
    @Published var excludedBundleIDs: [String] {
        didSet { defaults.set(excludedBundleIDs, forKey: Key.excludedBundleIDs) }
    }
    /// "system" / "ja" / "en"
    @Published var preferredLanguage: String {
        didSet {
            defaults.set(preferredLanguage, forKey: Key.preferredLanguage)
            Localizer.shared.apply(preferredLanguage)
        }
    }

    private init() {
        defaults.register(defaults: [
            Key.launchAtLogin: true,
            Key.showInMenuBar: true,
            Key.maxTextItems: 1000,
            Key.maxRetentionDays: 30,
            Key.maxImageBytes: 500 * 1024 * 1024,
            Key.maxImageItems: 200,
            Key.pasteStackEnabled: false,
            Key.onboardingCompleted: false,
            Key.excludedBundleIDs: [
                "com.agilebits.onepassword7",
                "com.1password.1password",
                "com.lastpass.LastPass"
            ],
            Key.preferredLanguage: "en"
        ])

        self.launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        self.showInMenuBar = defaults.bool(forKey: Key.showInMenuBar)
        self.maxTextItems = defaults.integer(forKey: Key.maxTextItems)
        self.maxRetentionDays = defaults.integer(forKey: Key.maxRetentionDays)
        self.maxImageBytes = defaults.integer(forKey: Key.maxImageBytes)
        self.maxImageItems = defaults.integer(forKey: Key.maxImageItems)
        self.pasteStackEnabled = defaults.bool(forKey: Key.pasteStackEnabled)
        self.onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted)
        self.excludedBundleIDs = defaults.stringArray(forKey: Key.excludedBundleIDs) ?? []
        let storedLanguage = defaults.string(forKey: Key.preferredLanguage) ?? "en"
        self.preferredLanguage = storedLanguage == "system" ? "en" : storedLanguage
        Localizer.shared.apply(self.preferredLanguage)
    }
}

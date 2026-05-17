import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var prefs: PreferencesStore
    @ObservedObject private var localizer = Localizer.shared

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label(NSLocalizedString("settings.tab.general", comment: ""), systemImage: "gear") }
            historyTab
                .tabItem { Label(NSLocalizedString("settings.tab.history", comment: ""), systemImage: "clock") }
            pasteStackTab
                .tabItem { Label("Queue", systemImage: "rectangle.stack") }
            aboutTab
                .tabItem { Label(NSLocalizedString("settings.tab.about", comment: ""), systemImage: "info.circle") }
        }
        .frame(width: 520, height: 420)
        .padding(20)
    }

    private var generalTab: some View {
        Form {
            Toggle(L("settings.launchAtLogin"), isOn: $prefs.launchAtLogin)
                .onChange(of: prefs.launchAtLogin) { _ in
                    LaunchAtLogin.set(enabled: prefs.launchAtLogin)
                }
            Toggle(L("settings.showInMenuBar"), isOn: $prefs.showInMenuBar)
            HStack {
                Text(L("settings.hotkey.popup"))
                Spacer()
                Text("Cmd+Shift+V").foregroundColor(.secondary)
            }
            Divider()
            HStack {
                Text(L("settings.language"))
                Spacer()
                Picker("", selection: $prefs.preferredLanguage) {
                    Text(L("settings.language.system")).tag("system")
                    Text("Japanese").tag("ja")
                    Text("English").tag("en")
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }
        }
        .padding()
    }

    private var historyTab: some View {
        Form {
            Stepper(value: $prefs.maxTextItems, in: 100...5000, step: 100) {
                Text("\(NSLocalizedString("settings.history.maxItems", comment: "")): \(prefs.maxTextItems)")
            }
            Stepper(value: $prefs.maxRetentionDays, in: 1...365) {
                Text("\(NSLocalizedString("settings.history.maxDays", comment: "")): \(prefs.maxRetentionDays)")
            }
            Stepper(value: Binding(
                get: { prefs.maxImageBytes / 1_048_576 },
                set: { prefs.maxImageBytes = $0 * 1_048_576 }
            ), in: 50...4096, step: 50) {
                Text("\(NSLocalizedString("settings.history.imageMaxBytes", comment: "")): \(prefs.maxImageBytes / 1_048_576) MB")
            }
        }
        .padding()
    }

    private var pasteStackTab: some View {
        Form {
            Toggle(NSLocalizedString("settings.pasteStack.enabled", comment: ""),
                   isOn: $prefs.pasteStackEnabled)
            Text(NSLocalizedString("settings.pasteStack.description", comment: ""))
                .font(.caption).foregroundColor(.secondary)
        }
        .padding()
    }

    private var aboutTab: some View {
        VStack(spacing: 8) {
            Image(systemName: "archivebox.fill").font(.system(size: 48))
            Text("Clippa").font(.title).bold()
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .foregroundColor(.secondary)
            Text("A small clipboard history app for Mac.")
                .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            Link("GitHub", destination: URL(string: "https://github.com/nagahara-naoki/Clippa")!)
                .font(.caption)
            Spacer()
        }
        .padding()
    }
}

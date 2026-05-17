import SwiftUI

struct OnboardingView: View {
    @State private var step: Int = 0
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            content
            Spacer()
            HStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            Button(step < 2 ? "Next" : NSLocalizedString("onboarding.done", comment: "")) {
                if step < 2 {
                    if step == 1 {
                        _ = Permissions.requestAccessibilityTrust()
                    }
                    step += 1
                } else {
                    onFinish()
                }
            }
            .keyboardShortcut(.defaultAction)
            .padding(.bottom)
        }
        .frame(width: 460, height: 360)
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            VStack(spacing: 10) {
                Image(systemName: "archivebox.fill").font(.system(size: 56))
                Text(NSLocalizedString("onboarding.welcome.title", comment: "")).font(.title2).bold()
                Text(NSLocalizedString("onboarding.welcome.subtitle", comment: ""))
                    .multilineTextAlignment(.center).foregroundColor(.secondary)
            }
        case 1:
            VStack(spacing: 10) {
                Image(systemName: "keyboard").font(.system(size: 56))
                Text(NSLocalizedString("onboarding.hotkey.title", comment: "")).font(.title3).bold()
                Text(NSLocalizedString("onboarding.hotkey.subtitle", comment: ""))
                    .multilineTextAlignment(.center).foregroundColor(.secondary)
            }
        default:
            VStack(spacing: 10) {
                Image(systemName: "lock.shield").font(.system(size: 56))
                Text(NSLocalizedString("onboarding.permission.title", comment: "")).font(.title3).bold()
                Text(NSLocalizedString("onboarding.permission.subtitle", comment: ""))
                    .multilineTextAlignment(.center).foregroundColor(.secondary)
                Button(NSLocalizedString("permission.accessibility.openSettings", comment: "")) {
                    Permissions.openAccessibilitySettings()
                }
            }
        }
    }
}

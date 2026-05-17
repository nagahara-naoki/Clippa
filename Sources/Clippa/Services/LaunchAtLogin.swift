import Foundation
import ServiceManagement

/// macOS 13+ では SMAppService、それ以前は SMLoginItemSetEnabled を使う。
enum LaunchAtLogin {
    static func set(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Log.error("LaunchAtLogin error: \(error)")
            }
        } else {
            // macOS 11/12 では Login Items Helper を使う方式が必要だが、
            // 簡略化のため初期版は何もしない（ユーザーに案内）。
            Log.info("LaunchAtLogin: macOS 13+ required for automatic registration")
        }
    }
}

import AppKit
import Carbon.HIToolbox

/// Carbon RegisterEventHotKey を使ったグローバルホットキー。
/// 初期割り当ては Cmd+Shift+V。
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let signature: OSType = OSType("HKDS".fourCharCode)
    private let hotKeyID: UInt32 = 1

    var onTrigger: (() -> Void)?

    private init() {}

    func register() {
        unregister()

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))

        let callback: EventHandlerUPP = { _, eventRef, userData -> OSStatus in
            guard let userData, let eventRef else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            var hkID = EventHotKeyID()
            GetEventParameter(eventRef,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hkID)
            if hkID.id == manager.hotKeyID {
                DispatchQueue.main.async {
                    manager.onTrigger?()
                }
            }
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(),
                            callback,
                            1,
                            &spec,
                            Unmanaged.passUnretained(self).toOpaque(),
                            &eventHandler)

        let hkID = EventHotKeyID(signature: signature, id: hotKeyID)
        // Cmd+Shift+V
        let keyCode = UInt32(kVK_ANSI_V)
        let modifiers = UInt32(cmdKey | shiftKey)
        let status = RegisterEventHotKey(keyCode, modifiers, hkID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status == noErr {
            Log.info("hotkey registered (Cmd+Shift+V)")
        } else {
            Log.error("hotkey registration failed: \(status)")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let h = eventHandler {
            RemoveEventHandler(h)
            eventHandler = nil
        }
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        var result: FourCharCode = 0
        for char in utf8.prefix(4) {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}

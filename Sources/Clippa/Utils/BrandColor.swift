import SwiftUI
import AppKit

/// Clippa 公式ブランドカラー (Pop Yellow)
enum BrandColor {
    static let primary       = Color(red: 0xFF/255, green: 0xD6/255, blue: 0x0A/255)  // #FFD60A
    static let primaryDark   = Color(red: 0xB5/255, green: 0x7E/255, blue: 0x20/255)  // #B57E20
    static let primaryLight  = Color(red: 0xFF/255, green: 0xE9/255, blue: 0xA8/255)  // #FFE9A8
    static let ink           = Color(red: 0x0F/255, green: 0x11/255, blue: 0x15/255)  // #0F1115 (高コントラスト)
    static let textBrown     = Color(red: 0x5C/255, green: 0x3A/255, blue: 0x00/255)  // #5C3A00
}

extension NSColor {
    static let brandPrimary      = NSColor(srgbRed: 0xFF/255, green: 0xD6/255, blue: 0x0A/255, alpha: 1)
    static let brandPrimaryDark  = NSColor(srgbRed: 0xB5/255, green: 0x7E/255, blue: 0x20/255, alpha: 1)
    static let brandPrimaryLight = NSColor(srgbRed: 0xFF/255, green: 0xE9/255, blue: 0xA8/255, alpha: 1)
    static let brandInk          = NSColor(srgbRed: 0x0F/255, green: 0x11/255, blue: 0x15/255, alpha: 1)
}

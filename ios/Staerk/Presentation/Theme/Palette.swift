import SwiftUI
import UIKit

/// Semantic colour tokens. Screens should reach for a role (`surface`, `inkSecondary`,
/// `accentInk`) rather than a raw value so light and dark stay balanced.
enum Palette {
    // MARK: Surfaces

    static let canvas = Color("StaerkBg")
    static let surface = Color("StaerkElevated")
    static let surfaceInset = Color(light: Color(hex: 0x767680, alpha: 0.08), dark: Color(hex: 0xFFFFFF, alpha: 0.06))
    static let surfaceInsetStrong = Color(light: Color(hex: 0x767680, alpha: 0.14), dark: Color(hex: 0xFFFFFF, alpha: 0.11))
    static let stroke = Color(light: Color(hex: 0x000000, alpha: 0.06), dark: Color(hex: 0xFFFFFF, alpha: 0.07))
    static let hairline = Color(light: Color(hex: 0x3C3C43, alpha: 0.12), dark: Color(hex: 0xFFFFFF, alpha: 0.09))

    // MARK: Ink

    static let ink = Color(light: Color(hex: 0x0B0B0C), dark: Color(hex: 0xF5F5F2))
    static let inkSecondary = Color(light: Color(hex: 0x3C3C43, alpha: 0.66), dark: Color(hex: 0xEBEBF5, alpha: 0.62))
    static let inkTertiary = Color(light: Color(hex: 0x3C3C43, alpha: 0.38), dark: Color(hex: 0xEBEBF5, alpha: 0.34))

    // MARK: Accent

    /// Signature volt. Use as a fill — never as text on light backgrounds.
    static let accent = Color(hex: 0xC6FF00)
    static let onAccent = Color(hex: 0x0B0B0C)
    /// Accent that stays legible as text, icons and system tint in both appearances.
    static let accentInk = Color(light: Color(hex: 0x4A7800), dark: Color(hex: 0xC6FF00))
    static let accentSoft = Color(light: Color(hex: 0x8DC300, alpha: 0.14), dark: Color(hex: 0xC6FF00, alpha: 0.10))

    // MARK: Data

    static let track = Color(light: Color(hex: 0x767680, alpha: 0.12), dark: Color(hex: 0xFFFFFF, alpha: 0.09))
    static let energy = Color(hex: 0xFF5A36)
    static let steps = Color(hex: 0xFF2D6F)
    static let distance = Color(hex: 0x3FC7FF)
    static let health = Color(hex: 0xFF375F)

    // MARK: Feedback

    static let danger = Color(light: Color(hex: 0xE5372C), dark: Color(hex: 0xFF5A4F))
    static let link = Color(light: Color(hex: 0x0A6CFF), dark: Color(hex: 0x4DA3FF))
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if cleaned.count == 3, let value = UInt32(cleaned, radix: 16) {
            let r = (value >> 8) & 0xF
            let g = (value >> 4) & 0xF
            let b = value & 0xF
            self.init(hex: (r << 20) | (r << 16) | (g << 12) | (g << 8) | (b << 4) | b)
            return
        }
        if cleaned.count == 6, let value = UInt32(cleaned, radix: 16) {
            self.init(hex: value)
            return
        }
        self.init(hex: 0xC6FF00)
    }

    init(light: Color, dark: Color) {
        self.init(
            uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
            }
        )
    }

    /// Darkens bright tints in light mode so they read as text or glyphs on white.
    var legible: Color {
        let base = UIColor(self)
        return Color(uiColor: UIColor { trait in
            guard trait.userInterfaceStyle != .dark else { return base }
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            guard base.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return base }
            return UIColor(hue: h, saturation: min(1, s * 1.05), brightness: min(b, 0.62), alpha: a)
        })
    }
}

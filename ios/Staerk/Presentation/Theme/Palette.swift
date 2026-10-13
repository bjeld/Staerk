import SwiftUI
import UIKit

enum Palette {
    static let bg = Color("StaerkBg")
    static let elevated = Color("StaerkElevated")
    static let volt = Color(hex: 0xC6FF00)
    static let voltForeground = Color.black
    static let ink = Color.primary
    static let muted = Color(light: Color(hex: 0x3C3C43, alpha: 0.60), dark: Color(hex: 0xEBEBF5, alpha: 0.55))
    static let hairline = Color(light: Color(hex: 0x3C3C43, alpha: 0.16), dark: Color(hex: 0x545458, alpha: 0.65))
    static let fill = Color(light: Color(hex: 0x787880, alpha: 0.12), dark: Color(hex: 0x787880, alpha: 0.28))
    static let fillStrong = Color(light: Color(hex: 0x787880, alpha: 0.20), dark: Color(hex: 0x787880, alpha: 0.40))
    static let ringTrack = Color(light: Color(hex: 0x787880, alpha: 0.16), dark: Color.white.opacity(0.12))
    static let danger = Color(hex: 0xFF453A)
    static let blue = Color(hex: 0x0A84FF)
}

enum Typeface {
    static func display(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .black, design: .default).width(.condensed)
    }

    static func title(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .heavy, design: .default).width(.condensed)
    }

    static var hero: Font { display(56) }
    static var screen: Font { display(34) }
    static var card: Font { title(22) }
    static var body: Font { .body }
    static var caption: Font { .subheadline }
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warn() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

extension ThemeMode {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
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
        var cleaned = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
}

extension View {
    func staerkCard() -> some View {
        self
            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    func staerkScreen() -> some View {
        self.background(Palette.bg.ignoresSafeArea())
    }
}

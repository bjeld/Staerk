import SwiftUI
import UIKit

enum Palette {
    static let bg = Color("StaerkBg")
    static let elevated = Color("StaerkElevated")
    static let accent = Color(hex: 0x30D158)
    static let accentForeground = Color(hex: 0x00330E)
    static let blue = Color(hex: 0x0A84FF)
    static let pink = Color(hex: 0xFF375F)
    static let cyan = Color(hex: 0x64D2FF)
    static let orange = Color(hex: 0xFF9F0A)
    static let ringMove = Color(hex: 0xFF375F)
    static let ringExercise = Color(hex: 0x30D158)
    static let ringStand = Color(hex: 0x64D2FF)
    static let danger = Color(hex: 0xFF453A)

    static let muted = Color(light: Color(hex: 0x3C3C43, alpha: 0.60), dark: Color(hex: 0xEBEBF5, alpha: 0.60))
    static let hairline = Color(light: Color(hex: 0x3C3C43, alpha: 0.18), dark: Color(hex: 0x545458, alpha: 0.65))
    static let fill = Color(light: Color(hex: 0x787880, alpha: 0.16), dark: Color(hex: 0x787880, alpha: 0.24))
    static let fillStrong = Color(light: Color(hex: 0x787880, alpha: 0.24), dark: Color(hex: 0x787880, alpha: 0.36))
    static let ringTrack = Color(light: Color(hex: 0x787880, alpha: 0.18), dark: Color.white.opacity(0.10))
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
            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
    }

    func staerkScreen() -> some View {
        self
            .background(Palette.bg.ignoresSafeArea())
            .environment(\.locale, Locale(identifier: "da_DK"))
    }
}

extension Double {
    var staerkWeight: String {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(self))
        }
        return String(format: "%g", self)
    }
}

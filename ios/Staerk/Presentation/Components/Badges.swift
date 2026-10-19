import SwiftUI
import UIKit

/// Rounded-square symbol tile. `soft` is the resting state; `solid` marks something achieved.
struct IconBadge: View {
    enum Style {
        case soft
        case solid
    }

    var symbol: String
    var tint: Color
    var size: CGFloat = 40
    var style: Style = .soft

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(style == .solid ? tint : tint.opacity(0.16))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(style == .solid ? tint.onTint : tint.legible)
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityHidden(true)
    }
}

struct Pill: View {
    var text: String
    var tint: Color = Palette.accent
    var filled = true

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .foregroundStyle(filled ? tint.onTint : tint.legible)
            .padding(.horizontal, Space.s + 2)
            .padding(.vertical, Space.xs)
            .background(filled ? tint : tint.opacity(0.16), in: Capsule())
    }
}

/// Calendar-style date chip for history rows.
struct DateBlock: View {
    var dateKey: String

    var body: some View {
        let date = Dates.parse(dateKey)
        VStack(spacing: 0) {
            Text(date, format: .dateTime.month(.abbreviated))
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.accentInk)
            Text("\(Dates.calendar.component(.day, from: date))")
                .font(Typeface.title(20))
                .foregroundStyle(Palette.ink)
                .monospacedDigit()
        }
        .frame(width: 44, height: 44)
        .insetSurface(radius: 12)
        .accessibilityHidden(true)
    }
}

/// The STRK mark — glossy flexed bicep (💪).
struct MuscleMark: View {
    var body: some View {
        Image("MuscleMark")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}

/// The mark on a black tile, matching the home-screen icon.
struct AppMark: View {
    var size: CGFloat = 96

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(Color.black)
            .frame(width: size, height: size)
            .overlay {
                MuscleMark()
                    .padding(size * 0.06)
            }
            .accessibilityHidden(true)
    }
}

extension Color {
    /// Black or white, whichever reads best on top of this colour.
    var onTint: Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let dark = Color(hex: 0x0B0B0C)
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return dark }
        func linear(_ c: CGFloat) -> CGFloat {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
        return luminance > 0.36 ? dark : .white
    }
}

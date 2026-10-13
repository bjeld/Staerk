import SwiftUI
import UIKit

/// Type scale. Display faces are condensed black — the STÆRK voice — and are reserved for
/// screen titles, workout names and numerals. Everything you read in a row is SF Pro.
enum Typeface {
    static func display(_ size: CGFloat, relativeTo style: UIFont.TextStyle = .largeTitle) -> Font {
        .system(size: scaled(size, style), weight: .black).width(.condensed)
    }

    static func title(_ size: CGFloat, relativeTo style: UIFont.TextStyle = .title2) -> Font {
        .system(size: scaled(size, style), weight: .heavy).width(.condensed)
    }

    static var screenTitle: Font { display(36) }
    static var hero: Font { display(60) }
    static var metric: Font { display(30, relativeTo: .title1) }
    static var metricSmall: Font { title(22, relativeTo: .title3) }
    static var cardTitle: Font { title(24, relativeTo: .title2) }
    static var rowTitle: Font { .body.weight(.semibold) }
    static var rowDetail: Font { .subheadline }
    static var eyebrow: Font { .caption.weight(.bold) }
    static var unit: Font { .footnote.weight(.semibold) }

    /// Scales with Dynamic Type, capped so numerals never break layouts.
    private static func scaled(_ size: CGFloat, _ style: UIFont.TextStyle) -> CGFloat {
        min(UIFontMetrics(forTextStyle: style).scaledValue(for: size), size * 1.35)
    }
}

enum Space {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let section: CGFloat = 36

    static let screen: CGFloat = 20
    static let card: CGFloat = 18
}

enum Radius {
    static let card: CGFloat = 26
    static let inner: CGFloat = 16
    static let control: CGFloat = 14
    static let small: CGFloat = 10
}

enum Motion {
    /// UI state flips: toggles, selection, segment changes.
    static let snappy = Animation.snappy(duration: 0.28)
    /// Completion moments — a little overshoot so it feels earned.
    static let bouncy = Animation.spring(response: 0.42, dampingFraction: 0.62)
    /// Progress filling up: rings, bars.
    static let fill = Animation.spring(response: 0.8, dampingFraction: 0.86)
    /// Press feedback on tappable surfaces.
    static let press = Animation.spring(response: 0.24, dampingFraction: 0.7)
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func celebrate() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred(intensity: 0.9)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
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

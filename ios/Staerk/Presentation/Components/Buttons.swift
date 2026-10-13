import SwiftUI

/// One button language for the whole app. Works for `Button`, `NavigationLink` and `PhotosPicker`.
struct StaerkButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case quiet
        case destructive
    }

    var kind: Kind
    var compact = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? .subheadline.weight(.bold) : .headline.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(foreground)
            .padding(.horizontal, compact ? Space.l : Space.xl)
            .frame(maxWidth: compact ? nil : .infinity)
            .frame(minHeight: compact ? 40 : 54)
            .background(background, in: RoundedRectangle(cornerRadius: compact ? 12 : Radius.control + 2, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .opacity(isEnabled || kind == .primary ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed && kind == .primary ? -0.04 : 0)
            .animation(Motion.press, value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary: return isEnabled ? Palette.onAccent : Palette.inkTertiary
        case .secondary: return Palette.ink
        case .quiet: return Palette.accentInk
        case .destructive: return Palette.danger
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return isEnabled ? Palette.accent : Palette.surfaceInsetStrong
        case .secondary: return Palette.surfaceInsetStrong
        case .quiet: return .clear
        case .destructive: return Palette.danger.opacity(0.1)
        }
    }
}

extension ButtonStyle where Self == StaerkButtonStyle {
    static var staerkPrimary: StaerkButtonStyle { StaerkButtonStyle(kind: .primary) }
    static var staerkSecondary: StaerkButtonStyle { StaerkButtonStyle(kind: .secondary) }
    static var staerkQuiet: StaerkButtonStyle { StaerkButtonStyle(kind: .quiet) }
    static var staerkDestructive: StaerkButtonStyle { StaerkButtonStyle(kind: .destructive) }
    static func staerk(_ kind: StaerkButtonStyle.Kind, compact: Bool = false) -> StaerkButtonStyle {
        StaerkButtonStyle(kind: kind, compact: compact)
    }
}

/// Subtle press feedback for tappable rows and cards.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.985

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

struct PrimaryButton: View {
    var title: String
    var symbol: String?
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            ButtonLabel(title: title, symbol: symbol)
        }
        .buttonStyle(.staerkPrimary)
        .disabled(!enabled)
    }
}

struct SecondaryButton: View {
    var title: String
    var symbol: String?
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            ButtonLabel(title: title, symbol: symbol)
        }
        .buttonStyle(.staerkSecondary)
    }
}

struct DangerButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.warn()
            action()
        } label: {
            Text(title)
        }
        .buttonStyle(.staerkDestructive)
    }
}

struct ButtonLabel: View {
    var title: String
    var symbol: String?

    var body: some View {
        HStack(spacing: Space.s) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.body.weight(.bold))
            }
            Text(title)
        }
    }
}

/// Circular icon control used in headers and card corners.
struct CircleIcon: View {
    var symbol: String
    var size: CGFloat = 40
    var tint: Color = Palette.ink
    var filled = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundStyle(filled ? Palette.onAccent : tint)
            .frame(width: size, height: size)
            .background(filled ? Palette.accent : Palette.surfaceInsetStrong, in: Circle())
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
    }
}

struct IconButton: View {
    var symbol: String
    var label: String
    var filled = false
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            CircleIcon(symbol: symbol, filled: filled)
        }
        .buttonStyle(PressableStyle(scale: 0.92))
        .accessibilityLabel(label)
    }
}

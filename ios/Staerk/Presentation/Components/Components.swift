import SwiftUI

// MARK: - Screen scaffold

/// Scrollable root for every screen: canvas background, screen margins and keyboard dismissal.
struct Screen<Content: View>: View {
    var spacing: CGFloat = Space.xxl
    var keyboardDismiss: ScrollDismissesKeyboardMode = .interactively
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            .padding(.horizontal, Space.screen)
            .padding(.top, Space.s)
            .padding(.bottom, Space.section)
        }
        .modifier(ScrollKeyboardDismiss(mode: keyboardDismiss))
        .scrollIndicators(.hidden)
        .background(Palette.canvas.ignoresSafeArea())
        .scrollEdgeEffectStyle(.soft, for: .top)
    }
}

struct ScreenHeader<Trailing: View>: View {
    var eyebrow: String?
    var title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .bottom, spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                if let eyebrow {
                    Eyebrow(text: eyebrow)
                }
                Text(title)
                    .font(Typeface.screenTitle)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSecondary)
                        .staerkWrappingText()
                        .padding(.top, Space.xxs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            trailing
        }
        .padding(.top, Space.m)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.init(eyebrow: eyebrow, title: title, subtitle: subtitle) { EmptyView() }
    }
}

// MARK: - Surfaces

struct Card<Content: View>: View {
    var padding: CGFloat? = Space.card
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding ?? 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

extension View {
    func cardSurface(radius: CGFloat = Radius.card) -> some View {
        background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Palette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Palette.stroke, lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func insetSurface(radius: CGFloat = Radius.inner) -> some View {
        background(Palette.surfaceInset, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - Sections

struct TitledSection<Content: View, Accessory: View>: View {
    var title: String
    var detail: String?
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Space.s)
                if let detail {
                    Text(detail)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Palette.inkSecondary)
                        .contentTransition(.numericText())
                }
                accessory
            }
            .padding(.horizontal, Space.xs)
            content
        }
    }
}

extension TitledSection where Accessory == EmptyView {
    init(title: String, detail: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, detail: detail, accessory: { EmptyView() }, content: content)
    }
}

struct Eyebrow: View {
    var text: String
    var color: Color = Palette.inkSecondary

    var body: some View {
        Text(text)
            .font(Typeface.eyebrow)
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

// MARK: - Rows

struct RowDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 1 / UIScreen.main.scale)
            .padding(.leading, inset)
    }
}

/// Standard list row: optional leading badge, title + detail, trailing accessory.
struct ListRow<Leading: View, Trailing: View>: View {
    var title: String
    var detail: String?
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .top, spacing: Space.m) {
            leading
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(title)
                    .font(Typeface.rowTitle)
                    .foregroundStyle(Palette.ink)
                    .staerkWrappingText()
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(Typeface.rowDetail)
                        .foregroundStyle(Palette.inkSecondary)
                        .staerkWrappingText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.m + 1)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

extension ListRow where Leading == EmptyView {
    init(title: String, detail: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.init(title: title, detail: detail, leading: { EmptyView() }, trailing: trailing)
    }
}

struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.bold))
            .foregroundStyle(Palette.inkTertiary)
            .accessibilityHidden(true)
    }
}

// MARK: - Callout

/// Accent-tinted note for coaching and progression advice.
struct Callout: View {
    var text: String
    var detail: String?
    var symbol: String = "arrow.up.right"

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            HStack(alignment: .top, spacing: Space.s) {
                Image(systemName: symbol)
                    .font(.footnote.weight(.black))
                    .foregroundStyle(Palette.accentInk)
                    .padding(.top, 1)
                    .accessibilityHidden(true)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Space.m + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: Radius.inner, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Empty states

struct EmptyState: View {
    var symbol: String
    var message: String
    var tint: Color = Palette.inkSecondary

    var body: some View {
        HStack(alignment: .top, spacing: Space.m) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(Palette.surfaceInset, in: Circle())
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Space.s)
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

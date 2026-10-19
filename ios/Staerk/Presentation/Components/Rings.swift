import SwiftUI

/// The single ring primitive. Everything circular in the app is built from this.
struct ProgressRing: View {
    var progress: Double
    var tint: Color = Palette.accent
    var lineWidth: CGFloat = 14

    @Environment(\.colorScheme) private var colorScheme

    private var clamped: Double { min(1, max(0, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: colorScheme == .dark && clamped > 0 ? tint.opacity(0.35) : .clear,
                    radius: lineWidth * 0.45
                )
                .opacity(clamped > 0 ? 1 : 0)
        }
        .padding(lineWidth / 2)
        .animation(Motion.fill, value: clamped)
    }
}

/// Large ring with arbitrary centre content — the Today hero.
struct HeroRing<Center: View>: View {
    var progress: Double
    var size: CGFloat = 148
    var lineWidth: CGFloat = 16
    var tint: Color = Palette.accent
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            ProgressRing(progress: progress, tint: tint, lineWidth: lineWidth)
            center
                .padding(lineWidth + Space.s)
        }
        .frame(width: size, height: size)
    }
}

import SwiftUI

struct CompletionRing: View {
    var progress: Double
    var size: CGFloat = 168
    var lineWidth: CGFloat = 16
    var label: String
    var caption: String

    var body: some View {
        let clamped = min(1, max(0, progress))
        ZStack {
            Circle()
                .stroke(Palette.ringTrack, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(Palette.volt, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Palette.volt.opacity(clamped > 0.02 ? 0.45 : 0), radius: 8)
                .animation(.easeInOut(duration: 0.7), value: clamped)
            VStack(spacing: 2) {
                Text(label)
                    .font(Typeface.display(size * 0.28))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.muted)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue("\(Int((clamped * 100).rounded()))%")
    }
}

struct ProgressRingView: View {
    var value: Double
    var maxValue: Double
    var color: Color
    var label: String
    var sub: String
    var size: CGFloat = 88
    var stroke: CGFloat = 8

    var body: some View {
        let pct = maxValue <= 0 ? 0 : min(1, value / maxValue)
        ZStack {
            Circle()
                .stroke(Palette.ringTrack, lineWidth: stroke)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: pct)
            VStack(spacing: 2) {
                Text(label)
                    .font(Typeface.title(20))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(sub)
                    .font(.caption2)
                    .foregroundStyle(Palette.muted)
            }
        }
        .frame(width: size, height: size)
    }
}

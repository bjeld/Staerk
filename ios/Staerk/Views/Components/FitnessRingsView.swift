import SwiftUI

struct FitnessRingsView: View {
    var move: Double
    var exercise: Double
    var stand: Double
    var size: CGFloat = 148

    private var stroke: CGFloat { size * 0.105 }
    private var gap: CGFloat { stroke * 0.28 }

    var body: some View {
        ZStack {
            RingTrack(progress: move, color: Palette.ringMove, lineWidth: stroke)
            RingTrack(progress: exercise, color: Palette.ringExercise, lineWidth: stroke)
                .padding(stroke + gap)
            RingTrack(progress: stand, color: Palette.ringStand, lineWidth: stroke)
                .padding((stroke + gap) * 2)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Vaneringe")
        .accessibilityValue("Kreatin \(percent(move)), vand \(percent(exercise)), alkoholfri \(percent(stand))")
    }

    private func percent(_ value: Double) -> String {
        "\(Int((min(1, max(0, value)) * 100).rounded())) procent"
    }
}

private struct RingTrack: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat

    var body: some View {
        let clamped = min(1, max(0, progress))
        ZStack {
            Circle()
                .stroke(Palette.ringTrack, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(clamped > 0.02 ? 0.55 : 0), radius: 4)
                .opacity(clamped > 0.02 ? 1 : 0)
                .animation(.easeInOut(duration: 0.7), value: clamped)
        }
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
                .opacity(pct > 0.02 ? 1 : 0)
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 17, weight: .semibold))
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.muted)
            }
        }
        .frame(width: size, height: size)
    }
}

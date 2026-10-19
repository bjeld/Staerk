import Charts
import SwiftUI

struct CircuitLogCard: View {
    var workout: WorkoutPlan
    var last: SessionLog?

    @Binding var durationMinutes: Double
    @Binding var rounds: Double
    @Binding var effort: Int?
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            if !workout.trimmedLocation.isEmpty || workout.targetDurationMinutes != nil || workout.targetRounds != nil {
                Card {
                    VStack(alignment: .leading, spacing: Space.s) {
                        if !workout.trimmedLocation.isEmpty {
                            Label(workout.trimmedLocation, systemImage: "mappin.and.ellipse")
                                .font(Typeface.rowTitle)
                                .foregroundStyle(Palette.ink)
                                .staerkWrappingText()
                        }
                        if let minutes = workout.targetDurationMinutes {
                            Text(L10n.format("circuit.target.duration", minutes))
                                .font(.subheadline)
                                .foregroundStyle(Palette.inkSecondary)
                                .staerkWrappingText()
                        }
                        if let targetRounds = workout.targetRounds {
                            Text(L10n.format("circuit.target.rounds", targetRounds))
                                .font(.subheadline)
                                .foregroundStyle(Palette.inkSecondary)
                                .staerkWrappingText()
                        }
                    }
                }
            }

            if !workout.stations.isEmpty {
                TitledSection(title: L10n.string("circuit.stations")) {
                    Card(padding: 0) {
                        ForEach(Array(workout.stations.enumerated()), id: \.element.id) { index, station in
                            HStack(alignment: .firstTextBaseline, spacing: Space.m) {
                                Text("\(index + 1)")
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Palette.onAccent)
                                    .frame(width: 28, height: 28)
                                    .background(Palette.accent, in: Circle())
                                Text(station.name)
                                    .font(Typeface.rowTitle)
                                    .foregroundStyle(Palette.ink)
                                    .staerkWrappingText()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, Space.l)
                            .padding(.vertical, Space.m)
                            if index < workout.stations.count - 1 {
                                RowDivider(inset: 56)
                            }
                        }
                    }
                }
            }

            if let last {
                Text(lastLine(last))
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSecondary)
                    .staerkWrappingText()
            } else {
                Text(L10n.string("circuit.first"))
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSecondary)
                    .staerkWrappingText()
            }

            Card {
                VStack(alignment: .leading, spacing: Space.l) {
                    HStack(alignment: .top, spacing: Space.s) {
                        labeledStepper(L10n.string("circuit.duration")) {
                            ValueStepper(
                                label: L10n.string("circuit.duration"),
                                value: $durationMinutes,
                                step: 5,
                                integer: true
                            )
                        }
                        labeledStepper(L10n.string("circuit.rounds")) {
                            ValueStepper(
                                label: L10n.string("circuit.rounds"),
                                value: $rounds,
                                step: 1,
                                integer: true
                            )
                        }
                    }
                    VStack(alignment: .leading, spacing: Space.s) {
                        Text(L10n.string("circuit.effort"))
                            .font(Typeface.eyebrow)
                            .foregroundStyle(Palette.inkSecondary)
                        EffortPicker(effort: $effort)
                    }
                    TextField(L10n.string("circuit.note.placeholder"), text: $note, axis: .vertical)
                        .lineLimit(2...5)
                        .font(.body)
                        .foregroundStyle(Palette.ink)
                }
            }
        }
    }

    private func lastLine(_ session: SessionLog) -> String {
        var parts: [String] = [Dates.prettyShort(key: session.dateKey)]
        if let minutes = session.resolvedDurationMinutes {
            parts.append(L10n.format("circuit.minutes.short", minutes))
        }
        if let rounds = session.rounds {
            parts.append(L10n.format("circuit.rounds.short", rounds))
        }
        if let effort = session.effort {
            parts.append(L10n.format("circuit.effort.short", effort))
        }
        return L10n.format("circuit.last", parts.joined(separator: " · "))
    }

    private func labeledStepper<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSecondary)
                .staerkWrappingText()
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EffortPicker: View {
    @Binding var effort: Int?

    var body: some View {
        HStack(spacing: Space.s) {
            ForEach(EffortRating.range, id: \.self) { value in
                let on = effort == value
                Button {
                    Haptics.selection()
                    effort = on ? nil : value
                } label: {
                    VStack(spacing: Space.xs) {
                        Text("\(value)")
                            .font(Typeface.title(20))
                            .foregroundStyle(on ? Palette.onAccent : Palette.ink)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(on ? Palette.accent : Palette.surfaceInset, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                        Text(L10n.string(EffortRating.localizationKey(value)))
                            .font(.caption2)
                            .foregroundStyle(Palette.inkSecondary)
                            .multilineTextAlignment(.center)
                            .staerkWrappingText()
                    }
                }
                .buttonStyle(PressableStyle(scale: 0.94))
            }
        }
        .animation(Motion.snappy, value: effort)
    }
}

struct CircuitProgressCard: View {
    var summary: CircuitProgress.Summary

    var body: some View {
        TitledSection(title: L10n.string("circuit.progress.title")) {
            HStack(spacing: Space.m) {
                metric(
                    title: L10n.string("circuit.progress.week"),
                    value: summary.scheduledThisWeek > 0
                        ? "\(summary.sessionsThisWeek)/\(summary.scheduledThisWeek)"
                        : "\(summary.sessionsThisWeek)"
                )
                metric(
                    title: L10n.string("circuit.progress.streak"),
                    value: "\(summary.streak)"
                )
                metric(
                    title: L10n.string("circuit.progress.time"),
                    value: formatMinutes(summary.totalMinutes)
                )
            }

            Card {
                VStack(alignment: .leading, spacing: Space.m) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L10n.string("circuit.progress.effort"))
                            .font(Typeface.cardTitle)
                            .foregroundStyle(Palette.ink)
                            .staerkWrappingText()
                        Spacer()
                        if let average = summary.averageEffort {
                            Text(L10n.format("circuit.progress.effort.avg", UnitConversion.format(average)))
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Palette.inkSecondary)
                        }
                    }
                    if summary.effortTrend.isEmpty {
                        Text(L10n.string("circuit.progress.effort.empty"))
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkSecondary)
                            .staerkWrappingText()
                    } else {
                        Chart(summary.effortTrend) { sample in
                            LineMark(
                                x: .value("D", sample.dateKey),
                                y: .value("E", sample.effort)
                            )
                            .foregroundStyle(Palette.accentInk)
                            .interpolationMethod(.catmullRom)
                            PointMark(
                                x: .value("D", sample.dateKey),
                                y: .value("E", sample.effort)
                            )
                            .foregroundStyle(Palette.accentInk)
                        }
                        .chartYScale(domain: 1...5)
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let key = value.as(String.self) {
                                        Text(Dates.prettyShort(key: key))
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    }
                }
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSecondary)
                    .staerkWrappingText()
                Text(value)
                    .font(Typeface.display(28))
                    .foregroundStyle(Palette.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes <= 0 { return "—" }
        if minutes >= 60 {
            let hours = minutes / 60
            let rest = minutes % 60
            if rest == 0 {
                return L10n.format("circuit.hours", hours)
            }
            return L10n.format("circuit.hours.minutes", hours, rest)
        }
        return L10n.format("circuit.minutes.short", minutes)
    }
}

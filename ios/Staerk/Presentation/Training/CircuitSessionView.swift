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
        VStack(alignment: .leading, spacing: 16) {
            if !workout.trimmedLocation.isEmpty || workout.targetDurationMinutes != nil || workout.targetRounds != nil {
                GroupedCard {
                    VStack(alignment: .leading, spacing: 8) {
                        if !workout.trimmedLocation.isEmpty {
                            Label(workout.trimmedLocation, systemImage: "mappin.and.ellipse")
                                .font(.headline)
                        }
                        if let minutes = workout.targetDurationMinutes {
                            Text(L10n.format("circuit.target.duration", minutes))
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                        }
                        if let targetRounds = workout.targetRounds {
                            Text(L10n.format("circuit.target.rounds", targetRounds))
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                        }
                    }
                    .padding(16)
                }
            }

            if !workout.stations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: L10n.string("circuit.stations"))
                    GroupedCard {
                        ForEach(Array(workout.stations.enumerated()), id: \.element.id) { index, station in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Palette.voltForeground)
                                    .frame(width: 24, height: 24)
                                    .background(Palette.volt, in: Circle())
                                Text(station.name)
                                    .font(.body.weight(.semibold))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            if index < workout.stations.count - 1 {
                                Divider().overlay(Palette.hairline).padding(.leading, 52)
                            }
                        }
                    }
                }
            }

            if let last {
                Text(lastLine(last))
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
            } else {
                Text(L10n.string("circuit.first"))
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
            }

            GroupedCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        NumberStepper(
                            label: L10n.string("circuit.duration"),
                            value: $durationMinutes,
                            step: 5,
                            integer: true
                        )
                        NumberStepper(
                            label: L10n.string("circuit.rounds"),
                            value: $rounds,
                            step: 1,
                            integer: true
                        )
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.string("circuit.effort"))
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                        EffortPicker(effort: $effort)
                    }
                    TextField(L10n.string("circuit.note.placeholder"), text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
                .padding(16)
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
}

struct EffortPicker: View {
    @Binding var effort: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(EffortRating.range, id: \.self) { value in
                let on = effort == value
                Button {
                    Haptics.tap()
                    effort = on ? nil : value
                } label: {
                    VStack(spacing: 4) {
                        Text("\(value)")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(on ? Palette.voltForeground : Color.primary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(on ? Palette.volt : Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text(L10n.string(EffortRating.localizationKey(value)))
                            .font(.caption2)
                            .foregroundStyle(Palette.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CircuitProgressCard: View {
    var summary: CircuitProgress.Summary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: L10n.string("circuit.progress.title"))
            HStack(spacing: 12) {
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

            GroupedCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(L10n.string("circuit.progress.effort"))
                            .font(Typeface.card)
                        Spacer()
                        if let average = summary.averageEffort {
                            Text(L10n.format("circuit.progress.effort.avg", UnitConversion.format(average)))
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Palette.muted)
                        }
                    }
                    if summary.effortTrend.isEmpty {
                        Text(L10n.string("circuit.progress.effort.empty"))
                            .foregroundStyle(Palette.muted)
                    } else {
                        Chart(summary.effortTrend) { sample in
                            LineMark(
                                x: .value("D", sample.dateKey),
                                y: .value("E", sample.effort)
                            )
                            .foregroundStyle(Palette.volt)
                            .interpolationMethod(.catmullRom)
                            PointMark(
                                x: .value("D", sample.dateKey),
                                y: .value("E", sample.effort)
                            )
                            .foregroundStyle(Palette.volt)
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
                .padding(16)
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                Text(value)
                    .font(Typeface.display(28))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
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

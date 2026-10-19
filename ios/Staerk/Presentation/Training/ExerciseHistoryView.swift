import Charts
import SwiftData
import SwiftUI

struct ExerciseHistoryView: View {
    var exerciseID: String

    @Query private var exerciseRows: [ExerciseRecord]
    @Query(sort: \SessionRecord.dateKey) private var sessionRows: [SessionRecord]
    @Query private var settingsRows: [SettingsRecord]

    private var exercise: ExerciseDefinition? { exerciseRows.first { $0.id == exerciseID }?.asDomain() }
    private var sessions: [SessionLog] { sessionRows.map { $0.asDomain() } }
    private var settings: UserSettings { settingsRows.first?.asDomain() ?? UserSettings() }

    private var points: [ExercisePoint] {
        sessions.filter(\.completed).compactMap { session in
            guard let block = session.exercises.first(where: { $0.exerciseId == exerciseID }) else { return nil }
            let done = block.sets.filter(\.done)
            guard let first = done.first else { return nil }
            let top = done.max(by: { $0.weightKg < $1.weightKg }) ?? first
            return ExercisePoint(
                id: session.id,
                dateKey: session.dateKey,
                weight: settings.weightUnit.fromKilograms(top.weightKg),
                reps: top.reps
            )
        }
    }

    var body: some View {
        Group {
            if let exercise {
                Screen {
                    ScreenHeader(eyebrow: exercise.muscleGroup.localizedName, title: exercise.name)
                    chartCard(exercise)
                    latestCard(exercise)
                }
            } else {
                Screen {
                    EmptyState(symbol: "hourglass", message: L10n.string("history.missing"))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func value(_ point: ExercisePoint, _ exercise: ExerciseDefinition) -> Double {
        exercise.logType == .seconds ? Double(point.reps) : point.weight
    }

    private func unit(_ exercise: ExerciseDefinition) -> String {
        exercise.logType == .seconds ? "s" : settings.weightUnit.symbol
    }

    private func chartCard(_ exercise: ExerciseDefinition) -> some View {
        Card(padding: Space.xl) {
            Eyebrow(text: exercise.logType == .seconds ? L10n.string("history.best.time") : L10n.string("history.top.weight"))
            if let last = points.last {
                HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                    Text(UnitConversion.format(value(last, exercise)))
                        .font(Typeface.hero)
                        .monospacedDigit()
                        .foregroundStyle(Palette.ink)
                    Text(unit(exercise))
                        .font(Typeface.title(20))
                        .foregroundStyle(Palette.inkSecondary)
                }
                Text(Dates.prettyLong(key: last.dateKey))
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSecondary)
            }

            if points.isEmpty {
                EmptyState(symbol: "chart.xyaxis.line", message: L10n.string("history.empty"))
                    .padding(.horizontal, -Space.l)
                    .padding(.bottom, -Space.l)
            } else {
                Chart(points) { point in
                    AreaMark(x: .value("D", point.dateKey), y: .value("V", value(point, exercise)))
                        .foregroundStyle(
                            LinearGradient(colors: [Palette.accent.opacity(0.28), Palette.accent.opacity(0)], startPoint: .top, endPoint: .bottom)
                        )
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("D", point.dateKey), y: .value("V", value(point, exercise)))
                        .foregroundStyle(Palette.accentInk)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("D", point.dateKey), y: .value("V", value(point, exercise)))
                        .foregroundStyle(Palette.accentInk)
                        .symbolSize(point.id == points.last?.id ? 70 : 24)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks { axisValue in
                        AxisValueLabel {
                            if let key = axisValue.as(String.self) {
                                Text(Dates.prettyShort(key: key))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            .foregroundStyle(Palette.hairline)
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
                .padding(.top, Space.l)
            }
        }
    }

    private func latestCard(_ exercise: ExerciseDefinition) -> some View {
        TitledSection(title: L10n.string("history.latest")) {
            Card {
                if let last = ProgressionCalculator.lastForExercise(sessions: sessions, exerciseId: exerciseID) {
                    ForEach(Array(last.sets.enumerated()), id: \.offset) { index, set in
                        HStack {
                            Text(L10n.format("session.set", index + 1))
                                .font(.subheadline)
                                .foregroundStyle(Palette.inkSecondary)
                            Spacer()
                            Text(AdviceFormatter.formatSet(logType: exercise.logType, set: set, unit: settings.weightUnit))
                                .font(.body.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Palette.ink)
                        }
                        .padding(.vertical, Space.s)
                        if index < last.sets.count - 1 {
                            RowDivider()
                        }
                    }
                    Callout(text: AdviceFormatter.text(ProgressionCalculator.suggestNext(exercise: exercise, last: last), unit: settings.weightUnit))
                        .padding(.top, Space.m)
                } else {
                    Text(L10n.string("history.none"))
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
        }
    }
}

private struct ExercisePoint: Identifiable {
    var id: String
    var dateKey: String
    var weight: Double
    var reps: Int
}

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
        ScrollView {
            if let exercise {
                VStack(alignment: .leading, spacing: 16) {
                    StaerkHeader(
                        title: exercise.name,
                        subtitle: exercise.muscleGroup.localizedName
                    )

                    GroupedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(exercise.logType == .seconds ? L10n.string("history.best.time") : L10n.string("history.top.weight"))
                                .font(Typeface.card)
                            if points.isEmpty {
                                Text(L10n.string("history.empty"))
                                    .foregroundStyle(Palette.muted)
                            } else {
                                Chart(points) { point in
                                    LineMark(
                                        x: .value("D", point.dateKey),
                                        y: .value("V", exercise.logType == .seconds ? Double(point.reps) : point.weight)
                                    )
                                    .foregroundStyle(Palette.volt)
                                    .interpolationMethod(.catmullRom)
                                    PointMark(
                                        x: .value("D", point.dateKey),
                                        y: .value("V", exercise.logType == .seconds ? Double(point.reps) : point.weight)
                                    )
                                    .foregroundStyle(Palette.volt)
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let key = value.as(String.self) {
                                                Text(Dates.prettyShort(key: key))
                                            }
                                        }
                                    }
                                }
                                .frame(height: 220)
                            }
                        }
                        .padding(16)
                    }

                    GroupedCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.string("history.latest")).font(Typeface.card)
                            if let last = ProgressionCalculator.lastForExercise(sessions: sessions, exerciseId: exerciseID) {
                                ForEach(Array(last.sets.enumerated()), id: \.offset) { index, set in
                                    HStack {
                                        Text(L10n.format("session.set", index + 1)).foregroundStyle(Palette.muted)
                                        Spacer()
                                        Text(AdviceFormatter.formatSet(logType: exercise.logType, set: set, unit: settings.weightUnit))
                                            .monospacedDigit()
                                    }
                                    .font(.subheadline)
                                }
                                Text(AdviceFormatter.text(ProgressionCalculator.suggestNext(exercise: exercise, last: last), unit: settings.weightUnit))
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.volt)
                                    .padding(.top, 4)
                            } else {
                                Text(L10n.string("history.none")).foregroundStyle(Palette.muted)
                            }
                        }
                        .padding(16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            } else {
                Text(L10n.string("history.missing")).foregroundStyle(Palette.muted).padding()
            }
        }
        .staerkKeyboard()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ExercisePoint: Identifiable {
    var id: String
    var dateKey: String
    var weight: Double
    var reps: Int
}

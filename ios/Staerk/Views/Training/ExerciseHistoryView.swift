import Charts
import SwiftData
import SwiftUI

struct ExerciseHistoryView: View {
    var exerciseID: String

    @Query private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.dateKey) private var sessions: [WorkoutSession]

    private var exercise: Exercise? {
        exercises.first(where: { $0.id == exerciseID })
    }

    private var points: [ExercisePoint] {
        sessions.filter(\.completed).compactMap { session in
            guard let block = session.exercises.first(where: { $0.exerciseId == exerciseID }) else { return nil }
            let done = block.sets.filter(\.done)
            guard let first = done.first else { return nil }
            let top = done.max(by: { $0.weight < $1.weight }) ?? first
            return ExercisePoint(
                id: session.id,
                dateKey: session.dateKey,
                label: Dates.prettyShort(key: session.dateKey),
                weight: top.weight,
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
                        subtitle: "\(exercise.muscleGroup.label) · Program \(exercise.workout.rawValue)"
                    )

                    GroupedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(exercise.logType == .seconds ? "Bedste tid" : "Topvægt")
                                .font(.system(size: 20, weight: .semibold))
                            if points.isEmpty {
                                Text("Ingen data endnu. Log et pas, så kommer grafen.")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Palette.muted)
                            } else {
                                Chart(points) { point in
                                    LineMark(
                                        x: .value("Dato", point.dateKey),
                                        y: .value(exercise.logType == .seconds ? "Sek" : "Kg", exercise.logType == .seconds ? Double(point.reps) : point.weight)
                                    )
                                    .foregroundStyle(Palette.accent)
                                    .interpolationMethod(.catmullRom)
                                    PointMark(
                                        x: .value("Dato", point.dateKey),
                                        y: .value(exercise.logType == .seconds ? "Sek" : "Kg", exercise.logType == .seconds ? Double(point.reps) : point.weight)
                                    )
                                    .foregroundStyle(Palette.accent)
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
                            Text("Seneste")
                                .font(.system(size: 20, weight: .semibold))
                            if let last = Progression.lastForExercise(sessions: sessions, exerciseId: exerciseID) {
                                ForEach(Array(last.sets.enumerated()), id: \.offset) { index, set in
                                    HStack {
                                        Text("Sæt \(index + 1)")
                                            .foregroundStyle(Palette.muted)
                                        Spacer()
                                        Text(Progression.formatSet(exercise: exercise, set: set))
                                            .monospacedDigit()
                                    }
                                    .font(.system(size: 15))
                                }
                                Text(Progression.suggestNext(exercise: exercise, last: last))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Palette.accent)
                                    .padding(.top, 4)
                            } else {
                                Text("Ingen historik.")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Palette.muted)
                            }
                        }
                        .padding(16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            } else {
                Text("Finder øvelsen…")
                    .foregroundStyle(Palette.muted)
                    .padding()
            }
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ExercisePoint: Identifiable {
    var id: String
    var dateKey: String
    var label: String
    var weight: Double
    var reps: Int
}

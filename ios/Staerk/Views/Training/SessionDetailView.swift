import SwiftData
import SwiftUI

struct SessionDetailView: View {
    var sessionID: String

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [WorkoutSession]
    @Query private var exercises: [Exercise]
    @State private var confirmDelete = false

    private var session: WorkoutSession? {
        sessions.first(where: { $0.id == sessionID })
    }

    var body: some View {
        ScrollView {
            if let session {
                VStack(alignment: .leading, spacing: 16) {
                    StaerkHeader(
                        title: "Program \(session.workout.rawValue)",
                        subtitle: "\(Dates.prettyLong(key: session.dateKey)) · \(session.completed ? "Afsluttet" : "Kladde")"
                    )

                    ForEach(session.exercises) { block in
                        if let exercise = exercises.first(where: { $0.id == block.exerciseId }) {
                            GroupedCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.name)
                                                .font(.system(size: 20, weight: .semibold))
                                            Text(exercise.muscleGroup.label)
                                                .font(.system(size: 13))
                                                .foregroundStyle(Palette.muted)
                                        }
                                        Spacer()
                                        NavigationLink("Graf") {
                                            ExerciseHistoryView(exerciseID: exercise.id)
                                        }
                                        .font(.system(size: 15))
                                        .foregroundStyle(Palette.blue)
                                    }
                                    ForEach(Array(block.sets.enumerated()), id: \.element.id) { index, set in
                                        HStack {
                                            Text("Sæt \(index + 1)")
                                                .foregroundStyle(Palette.muted)
                                            Spacer()
                                            Text(setLine(exercise: exercise, set: set))
                                                .monospacedDigit()
                                        }
                                        .font(.system(size: 15))
                                    }
                                }
                                .padding(16)
                            }
                        }
                    }

                    GroupedCard {
                        DangerButton(title: "Slet pas") {
                            confirmDelete = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            } else {
                Text("Finder passet…")
                    .foregroundStyle(Palette.muted)
                    .padding()
            }
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Slet dette pas?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Slet pas", role: .destructive) {
                if let session {
                    context.delete(session)
                    try? context.save()
                    dismiss()
                }
            }
            Button("Annuller", role: .cancel) {}
        }
    }

    private func setLine(exercise: Exercise, set: SetLog) -> String {
        let body = exercise.logType == .seconds ? "\(set.reps) sek" : "\(set.weight.staerkWeight) kg × \(set.reps)"
        return set.done ? "\(body) ✓" : body
    }
}

import SwiftData
import SwiftUI

struct SessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(HealthKitService.self) private var health
    @Query(filter: #Predicate<Exercise> { !$0.archived }, sort: \Exercise.order) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.dateKey, order: .reverse) private var sessions: [WorkoutSession]

    @State private var letter: WorkoutLetter?
    @State private var blocks: [SessionExerciseBlock] = []
    @State private var startedAt = Date()
    @State private var saving = false
    @State private var didLoad = false

    private var resolved: WorkoutLetter {
        letter ?? Schedule.pickWorkoutLetter(sessions: sessions)
    }

    private var plan: [Exercise] {
        exercises.filter { $0.workout == resolved }.sorted { $0.order < $1.order }
    }

    private var doneSets: Int { blocks.reduce(0) { $0 + $1.sets.filter(\.done).count } }
    private var totalSets: Int { blocks.reduce(0) { $0 + $1.sets.count } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StaerkHeader(
                    title: "Program \(resolved.rawValue)",
                    subtitle: "Opvarm 5 min + ét let sæt. 1–2 reps i reserve. \(doneSets)/\(totalSets) sæt."
                )

                Picker("Program", selection: Binding(
                    get: { resolved },
                    set: { switchLetter($0) }
                )) {
                    Text("Program A").tag(WorkoutLetter.A)
                    Text("Program B").tag(WorkoutLetter.B)
                }
                .pickerStyle(.segmented)

                if blocks.isEmpty {
                    Text("Indlæser program…")
                        .foregroundStyle(Palette.muted)
                        .padding(.top, 12)
                }

                ForEach(plan, id: \.id) { exercise in
                    if let index = blocks.firstIndex(where: { $0.exerciseId == exercise.id }) {
                        exerciseCard(exercise: exercise, blockIndex: index)
                    }
                }

                PrimaryButton(title: "Gem og afslut pas", enabled: !saving) {
                    Task { await complete(done: true) }
                }
                Button("Gem som kladde") {
                    Task { await complete(done: false) }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear(perform: loadIfNeeded)
        .onChange(of: exercises.count) { _, _ in
            loadIfNeeded()
        }
    }

    private func exerciseCard(exercise: Exercise, blockIndex: Int) -> some View {
        let last = Progression.lastForExercise(sessions: sessions, exerciseId: exercise.id)
        return GroupedCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.system(size: 20, weight: .semibold))
                        Text("\(exercise.muscleGroup.label) · \(exercise.defaultSets) sæt")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    NavigationLink("Historik") {
                        ExerciseHistoryView(exerciseID: exercise.id)
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.blue)
                }

                if let last {
                    Text("Sidste gang (\(last.dateKey)): \(last.sets.map { Progression.formatSet(exercise: exercise, set: $0) }.joined(separator: " · "))")
                        .font(.system(size: 15))
                } else {
                    Text("Ingen tidligere tal — start konservativt.")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                }

                Text(Progression.suggestNext(exercise: exercise, last: last))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.accent)

                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                }

                ForEach(blocks[blockIndex].sets.indices, id: \.self) { setIndex in
                    setEditor(exercise: exercise, blockIndex: blockIndex, setIndex: setIndex)
                }
            }
            .padding(16)
        }
    }

    private func setEditor(exercise: Exercise, blockIndex: Int, setIndex: Int) -> some View {
        let set = blocks[blockIndex].sets[setIndex]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sæt \(setIndex + 1)")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                Spacer()
                Button {
                    blocks[blockIndex].sets[setIndex].done.toggle()
                } label: {
                    Text(set.done ? "Sat" : "Markér")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(set.done ? Palette.accentForeground : .primary)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(
                            set.done ? Palette.accent : Palette.elevated,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                if exercise.logType == .reps {
                    NumberStepper(
                        label: "Kg",
                        value: Binding(
                            get: { blocks[blockIndex].sets[setIndex].weight },
                            set: { blocks[blockIndex].sets[setIndex].weight = $0 }
                        ),
                        step: 2.5
                    )
                }
                NumberStepper(
                    label: exercise.logType == .seconds ? "Sekunder" : "Reps",
                    value: Binding(
                        get: { Double(blocks[blockIndex].sets[setIndex].reps) },
                        set: { blocks[blockIndex].sets[setIndex].reps = Int($0.rounded()) }
                    ),
                    step: exercise.logType == .seconds ? 5 : 1,
                    integer: true
                )
            }
        }
        .padding(8)
        .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func loadIfNeeded() {
        guard !didLoad, !exercises.isEmpty else { return }
        let pick = Schedule.pickWorkoutLetter(sessions: sessions)
        letter = pick
        loadBlocks(for: pick)
        startedAt = Date()
        didLoad = true
    }

    private func switchLetter(_ next: WorkoutLetter) {
        letter = next
        loadBlocks(for: next)
    }

    private func loadBlocks(for letter: WorkoutLetter) {
        let chosen = exercises.filter { $0.workout == letter }.sorted { $0.order < $1.order }
        blocks = chosen.map { Progression.defaultSets(from: Progression.lastForExercise(sessions: sessions, exerciseId: $0.id), exercise: $0) }
    }

    private func complete(done: Bool) async {
        saving = true
        let session = WorkoutSession(
            dateKey: Dates.key(),
            workout: resolved,
            completed: done,
            startedAt: startedAt,
            finishedAt: Date(),
            exercises: blocks
        )
        context.insert(session)
        try? context.save()
        if done {
            await health.saveStrengthWorkout(start: startedAt, end: Date())
        }
        saving = false
        dismiss()
    }
}

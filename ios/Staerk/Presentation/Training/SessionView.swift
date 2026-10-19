import SwiftData
import SwiftUI

struct SessionView: View {
    @Environment(AppContainer.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(HealthKitService.self) private var health
    @Query(filter: #Predicate<ExerciseRecord> { !$0.archived }, sort: \ExerciseRecord.sortOrder)
    private var exerciseRows: [ExerciseRecord]
    @Query(sort: \SessionRecord.dateKey, order: .reverse) private var sessionRows: [SessionRecord]
    @Query(sort: \WorkoutRecord.sortOrder) private var workoutRows: [WorkoutRecord]
    @Query private var scheduleRows: [ScheduleRecord]
    @Query private var settingsRows: [SettingsRecord]
    @Query(sort: \HabitRecord.sortOrder) private var habitRows: [HabitRecord]

    @State private var workoutID: String?
    @State private var blocks: [SessionExerciseBlock] = []
    @State private var startedAt = Date()
    @State private var saving = false
    @State private var didLoad = false
    @State private var durationMinutes: Double = 30
    @State private var rounds: Double = 2
    @State private var effort: Int?
    @State private var note = ""

    private var settings: UserSettings { settingsRows.first?.asDomain() ?? UserSettings() }
    private var workouts: [WorkoutPlan] { workoutRows.map { $0.asDomain() } }
    private var sessions: [SessionLog] { sessionRows.map { $0.asDomain() } }
    private var schedule: WeeklySchedule { scheduleRows.first?.asDomain() ?? WeeklySchedule() }
    private var resolved: WorkoutPlan? {
        workouts.first { $0.id == workoutID } ?? ScheduleResolver.pickWorkout(schedule: schedule, workouts: workouts, sessions: sessions)
    }
    private var plan: [ExerciseDefinition] {
        guard let resolved, !resolved.isCircuit else { return [] }
        return exerciseRows.filter { $0.workoutID == resolved.id }.map { $0.asDomain() }
    }
    private var doneSets: Int { blocks.reduce(0) { $0 + $1.sets.filter(\.done).count } }
    private var totalSets: Int { blocks.reduce(0) { $0 + $1.sets.count } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StaerkHeader(
                    title: resolved?.name ?? L10n.string("session.title"),
                    subtitle: subtitle
                )

                if workouts.count > 1 {
                    Picker(L10n.string("session.workout"), selection: Binding(
                        get: { resolved?.id ?? "" },
                        set: { switchWorkout($0) }
                    )) {
                        ForEach(workouts) { workout in
                            Text(workout.name).tag(workout.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let resolved, resolved.isCircuit {
                    CircuitLogCard(
                        workout: resolved,
                        last: CircuitProgress.lastCircuit(in: sessions, workoutID: resolved.id),
                        durationMinutes: $durationMinutes,
                        rounds: $rounds,
                        effort: $effort,
                        note: $note
                    )
                    PrimaryButton(title: L10n.string("session.circuit.done"), enabled: !saving) {
                        Task { await completeCircuit() }
                    }
                } else {
                    ForEach(plan) { exercise in
                        if let index = blocks.firstIndex(where: { $0.exerciseId == exercise.id }) {
                            exerciseCard(exercise: exercise, blockIndex: index)
                        }
                    }

                    PrimaryButton(title: L10n.string("session.finish"), enabled: !saving) {
                        Task { await completeDetailed(done: true) }
                    }
                    Button(L10n.string("session.draft")) {
                        Task { await completeDetailed(done: false) }
                    }
                    .font(.headline)
                    .foregroundStyle(Palette.blue)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .staerkKeyboard()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear(perform: loadIfNeeded)
        .onChange(of: exerciseRows.count) { _, _ in loadIfNeeded() }
        .onChange(of: workoutRows.count) { _, _ in loadIfNeeded() }
    }

    private var subtitle: String {
        guard let resolved else { return L10n.string("session.title") }
        if resolved.isCircuit {
            if resolved.trimmedLocation.isEmpty {
                return L10n.string("session.circuit.subtitle")
            }
            return resolved.trimmedLocation
        }
        return L10n.format("session.subtitle", doneSets, totalSets)
    }

    private func exerciseCard(exercise: ExerciseDefinition, blockIndex: Int) -> some View {
        let last = ProgressionCalculator.lastForExercise(sessions: sessions, exerciseId: exercise.id)
        return GroupedCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name).font(Typeface.title(20))
                        Text("\(exercise.muscleGroup.localizedName) · \(exercise.defaultSets)")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    NavigationLink(L10n.string("session.history")) {
                        ExerciseHistoryView(exerciseID: exercise.id)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Palette.blue)
                }

                if let last {
                    Text(L10n.format(
                        "session.last",
                        last.dateKey,
                        last.sets.map { AdviceFormatter.formatSet(logType: exercise.logType, set: $0, unit: settings.weightUnit) }.joined(separator: " · ")
                    ))
                    .font(.subheadline)
                } else {
                    Text(L10n.string("session.first"))
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                }

                Text(AdviceFormatter.text(ProgressionCalculator.suggestNext(exercise: exercise, last: last), unit: settings.weightUnit))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.volt)

                if !exercise.notes.isEmpty {
                    Text(exercise.notes).font(.footnote).foregroundStyle(Palette.muted)
                }

                ForEach(blocks[blockIndex].sets.indices, id: \.self) { setIndex in
                    setEditor(exercise: exercise, blockIndex: blockIndex, setIndex: setIndex)
                }
            }
            .padding(16)
        }
    }

    private func setEditor(exercise: ExerciseDefinition, blockIndex: Int, setIndex: Int) -> some View {
        let set = blocks[blockIndex].sets[setIndex]
        let displayWeight = settings.weightUnit.fromKilograms(set.weightKg)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.format("session.set", setIndex + 1))
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                Spacer()
                Button {
                    Haptics.tap()
                    blocks[blockIndex].sets[setIndex].done.toggle()
                    if blocks[blockIndex].sets[setIndex].done { Haptics.success() }
                } label: {
                    Text(set.done ? L10n.string("session.set.done") : L10n.string("session.set.mark"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(set.done ? Palette.voltForeground : .primary)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(set.done ? Palette.volt : Palette.elevated, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                if exercise.logType == .reps {
                    NumberStepper(
                        label: settings.weightUnit.symbol,
                        value: Binding(
                            get: { displayWeight },
                            set: { blocks[blockIndex].sets[setIndex].weightKg = settings.weightUnit.toKilograms($0) }
                        ),
                        step: settings.weightUnit == .pound ? 5 : 2.5
                    )
                }
                NumberStepper(
                    label: exercise.logType == .seconds ? L10n.string("session.seconds") : L10n.string("session.reps"),
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
        .background(Palette.fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        guard let pick = ScheduleResolver.pickWorkout(schedule: schedule, workouts: workouts, sessions: sessions) else { return }
        workoutID = pick.id
        applyWorkout(pick)
        startedAt = Date()
        didLoad = true
    }

    private func switchWorkout(_ id: String) {
        workoutID = id
        if let workout = workouts.first(where: { $0.id == id }) {
            applyWorkout(workout)
        } else {
            loadBlocks(for: id)
        }
    }

    private func applyWorkout(_ workout: WorkoutPlan) {
        if workout.isCircuit {
            let last = CircuitProgress.lastCircuit(in: sessions, workoutID: workout.id)
            durationMinutes = Double(last?.durationMinutes ?? workout.targetDurationMinutes ?? 30)
            rounds = Double(last?.rounds ?? workout.targetRounds ?? 2)
            effort = nil
            note = ""
            blocks = []
        } else {
            loadBlocks(for: workout.id)
        }
    }

    private func loadBlocks(for workoutID: String) {
        let chosen = exerciseRows.filter { $0.workoutID == workoutID }.map { $0.asDomain() }
        blocks = chosen.map {
            ProgressionCalculator.defaultSets(
                from: ProgressionCalculator.lastForExercise(sessions: sessions, exerciseId: $0.id),
                exercise: $0
            )
        }
    }

    private func completeDetailed(done: Bool) async {
        guard let resolved else { return }
        saving = true
        let session = SessionLog(
            dateKey: Dates.key(),
            workoutID: resolved.id,
            workoutName: resolved.name,
            completed: done,
            startedAt: startedAt,
            finishedAt: Date(),
            exercises: blocks,
            kind: .detailed
        )
        try? app.sessions.save(session)
        if done {
            await health.saveWorkout(kind: .detailed, start: startedAt, end: session.healthKitEndDate)
            markWorkoutHabit()
        }
        saving = false
        dismiss()
    }

    private func completeCircuit() async {
        guard let resolved else { return }
        saving = true
        let elapsed = max(1, Int(Date().timeIntervalSince(startedAt) / 60))
        let typedDuration = Int(durationMinutes.rounded())
        let session = SessionLog(
            dateKey: Dates.key(),
            workoutID: resolved.id,
            workoutName: resolved.name,
            completed: true,
            startedAt: startedAt,
            finishedAt: Date(),
            note: note,
            exercises: [],
            kind: .circuit,
            durationMinutes: typedDuration > 0 ? typedDuration : elapsed,
            rounds: Int(rounds.rounded()),
            effort: effort
        )
        try? app.sessions.save(session)
        await health.saveWorkout(kind: .circuit, start: startedAt, end: session.healthKitEndDate)
        markWorkoutHabit()
        saving = false
        Haptics.success()
        dismiss()
    }

    private func markWorkoutHabit() {
        if let workoutHabit = habitRows.map({ $0.asDomain() }).first(where: { $0.kind == .workout && !$0.archived }) {
            let entry = HabitEntry(habitID: workoutHabit.id, dateKey: Dates.key(), boolValue: true)
            try? app.habits.upsert(entry)
        }
    }
}

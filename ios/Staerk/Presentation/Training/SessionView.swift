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
        Screen(spacing: Space.l) {
            VStack(alignment: .leading, spacing: Space.l) {
                ScreenHeader(
                    eyebrow: Dates.prettyLong(Date()),
                    title: resolved?.name ?? L10n.string("session.title"),
                    subtitle: sessionSubtitle
                )
                if resolved?.isCircuit != true {
                    VStack(alignment: .leading, spacing: Space.s) {
                        LinearProgress(progress: totalSets > 0 ? Double(doneSets) / Double(totalSets) : 0, height: 8)
                        Text(L10n.format("session.subtitle", doneSets, totalSets))
                            .font(.footnote.weight(.medium).monospacedDigit())
                            .foregroundStyle(Palette.inkSecondary)
                            .contentTransition(.numericText(value: Double(doneSets)))
                            .animation(Motion.snappy, value: doneSets)
                    }
                }
            }

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
            } else {
                ForEach(plan) { exercise in
                    if let index = blocks.firstIndex(where: { $0.exerciseId == exercise.id }) {
                        exerciseCard(exercise: exercise, blockIndex: index)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear(perform: loadIfNeeded)
        .onChange(of: exerciseRows.count) { _, _ in loadIfNeeded() }
        .onChange(of: workoutRows.count) { _, _ in loadIfNeeded() }
    }

    private var sessionSubtitle: String? {
        guard let resolved, resolved.isCircuit else { return nil }
        if resolved.trimmedLocation.isEmpty {
            return L10n.string("session.circuit.subtitle")
        }
        return resolved.trimmedLocation
    }

    private var actionBar: some View {
        VStack(spacing: Space.xs) {
            if resolved?.isCircuit == true {
                PrimaryButton(title: L10n.string("session.circuit.done"), symbol: "checkmark", enabled: !saving) {
                    Task { await completeCircuit() }
                }
            } else {
                PrimaryButton(title: L10n.string("session.finish"), symbol: "checkmark", enabled: !saving) {
                    Task { await completeDetailed(done: true) }
                }
                Button(L10n.string("session.draft")) {
                    Task { await completeDetailed(done: false) }
                }
                .buttonStyle(.staerk(.quiet, compact: true))
                .disabled(saving)
            }
        }
        .padding(.horizontal, Space.screen)
        .padding(.top, Space.m)
        .padding(.bottom, Space.xs)
        .background(.bar)
        .overlay(alignment: .top) { RowDivider() }
    }

    // MARK: Exercise

    private func exerciseCard(exercise: ExerciseDefinition, blockIndex: Int) -> some View {
        let last = ProgressionCalculator.lastForExercise(sessions: sessions, exerciseId: exercise.id)
        let block = blocks[blockIndex]
        let completed = !block.sets.isEmpty && block.sets.allSatisfy(\.done)
        return Card {
            HStack(alignment: .top, spacing: Space.m) {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(exercise.name)
                        .font(Typeface.cardTitle)
                        .foregroundStyle(Palette.ink)
                        .staerkWrappingText()
                    Text("\(exercise.muscleGroup.localizedName) · \(exercise.defaultSets) × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)")
                        .font(.footnote)
                        .foregroundStyle(Palette.inkSecondary)
                        .staerkWrappingText()
                }
                Spacer(minLength: 0)
                NavigationLink {
                    ExerciseHistoryView(exerciseID: exercise.id)
                } label: {
                    CircleIcon(symbol: "chart.xyaxis.line", size: 36, tint: Palette.inkSecondary)
                }
                .buttonStyle(PressableStyle(scale: 0.92))
                .accessibilityLabel(L10n.string("session.history"))
            }

            coachNote(exercise: exercise, last: last)
                .padding(.top, Space.m)

            if !exercise.notes.isEmpty {
                Text(exercise.notes)
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSecondary)
                    .staerkWrappingText()
                    .padding(.top, Space.m)
            }

            setTable(exercise: exercise, blockIndex: blockIndex)
                .padding(.top, Space.l)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.accentInk.opacity(completed ? 0.6 : 0), lineWidth: 1.5)
        }
        .animation(Motion.snappy, value: completed)
    }

    private func coachNote(exercise: ExerciseDefinition, last: LastPerformance?) -> some View {
        let history = last.map { last in
            L10n.format(
                "session.last",
                Dates.prettyShort(key: last.dateKey),
                last.sets.map { AdviceFormatter.formatSet(logType: exercise.logType, set: $0, unit: settings.weightUnit) }.joined(separator: " · ")
            )
        }
        return Callout(
            text: AdviceFormatter.text(ProgressionCalculator.suggestNext(exercise: exercise, last: last), unit: settings.weightUnit),
            detail: history ?? L10n.string("session.first")
        )
    }

    // MARK: Sets

    private func setTable(exercise: ExerciseDefinition, blockIndex: Int) -> some View {
        let repsLabel = exercise.logType == .seconds ? L10n.string("session.seconds") : L10n.string("session.reps")
        return VStack(spacing: Space.s) {
            HStack(spacing: Space.m) {
                Color.clear.frame(width: 44, height: 1)
                if exercise.logType == .reps {
                    columnLabel(settings.weightUnit.symbol)
                }
                columnLabel(repsLabel)
            }
            ForEach(blocks[blockIndex].sets.indices, id: \.self) { setIndex in
                setRow(exercise: exercise, blockIndex: blockIndex, setIndex: setIndex, repsLabel: repsLabel)
            }
        }
    }

    private func columnLabel(_ text: String) -> some View {
        Text(text)
            .font(Typeface.eyebrow)
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(Palette.inkTertiary)
            .frame(maxWidth: .infinity)
    }

    private func setRow(exercise: ExerciseDefinition, blockIndex: Int, setIndex: Int, repsLabel: String) -> some View {
        let set = blocks[blockIndex].sets[setIndex]
        let displayWeight = settings.weightUnit.fromKilograms(set.weightKg)
        let setLabel = L10n.format("session.set", setIndex + 1)
        return HStack(spacing: Space.m) {
            Button {
                Haptics.tap()
                withAnimation(Motion.bouncy) {
                    blocks[blockIndex].sets[setIndex].done.toggle()
                }
                if blocks[blockIndex].sets[setIndex].done { Haptics.success() }
            } label: {
                CompletionCheck(isOn: set.done, tint: Palette.accent, size: 34, label: "\(setIndex + 1)")
                    .frame(width: 44, height: 46)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.9))
            .accessibilityLabel(setLabel)
            .accessibilityValue(set.done ? L10n.string("session.set.done") : L10n.string("a11y.todo"))

            if exercise.logType == .reps {
                ValueStepper(
                    label: "\(setLabel), \(settings.weightUnit.symbol)",
                    value: Binding(
                        get: { displayWeight },
                        set: { blocks[blockIndex].sets[setIndex].weightKg = settings.weightUnit.toKilograms($0) }
                    ),
                    step: settings.weightUnit == .pound ? 5 : 2.5
                )
            }
            ValueStepper(
                label: "\(setLabel), \(repsLabel)",
                value: Binding(
                    get: { Double(blocks[blockIndex].sets[setIndex].reps) },
                    set: { blocks[blockIndex].sets[setIndex].reps = Int($0.rounded()) }
                ),
                step: exercise.logType == .seconds ? 5 : 1,
                integer: true
            )
        }
        .opacity(set.done ? 0.72 : 1)
        .animation(Motion.snappy, value: set.done)
    }

    // MARK: Data

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
            Haptics.celebrate()
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
        Haptics.celebrate()
        saving = false
        dismiss()
    }

    private func markWorkoutHabit() {
        if let workoutHabit = habitRows.map({ $0.asDomain() }).first(where: { $0.kind == .workout && !$0.archived }) {
            let entry = HabitEntry(habitID: workoutHabit.id, dateKey: Dates.key(), boolValue: true)
            try? app.habits.upsert(entry)
        }
    }
}

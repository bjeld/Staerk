import SwiftData
import SwiftUI

struct ProgramEditorView: View {
    @Environment(AppContainer.self) private var app
    @Query(sort: \ProgramRecord.sortOrder) private var programRows: [ProgramRecord]
    @Query(sort: \WorkoutRecord.sortOrder) private var workoutRows: [WorkoutRecord]
    @Query(sort: \ExerciseRecord.sortOrder) private var exerciseRows: [ExerciseRecord]
    @State private var programName: String = ""
    @State private var editingExercise: ExerciseDefinition?
    @State private var confirmTemplate: ProgramBlueprint?
    @State private var newWorkoutName = ""

    private var program: TrainingProgram? { programRows.first { $0.isActive }?.asDomain() ?? programRows.first?.asDomain() }
    private var workouts: [WorkoutPlan] {
        guard let program else { return [] }
        return workoutRows.filter { $0.programID == program.id }.map { $0.asDomain() }
    }

    var body: some View {
        Screen(keyboardDismiss: .immediately) {
            ScreenHeader(title: L10n.string("program.edit.title"), subtitle: L10n.string("program.edit.body"))

            Card {
                Eyebrow(text: L10n.string("program.name"))
                TextField(L10n.string("program.name"), text: Binding(
                    get: { programName.isEmpty ? (program?.name ?? "") : programName },
                    set: { programName = $0 }
                ))
                .font(Typeface.cardTitle)
                .foregroundStyle(Palette.ink)
                .submitLabel(.done)
                .padding(.top, Space.s)
                .onSubmit(saveName)
            }

            ForEach(workouts) { workout in
                workoutSection(workout)
            }

            Card(padding: Space.m) {
                HStack(spacing: Space.m) {
                    TextField(L10n.string("program.workout.name"), text: $newWorkoutName)
                        .font(.body)
                        .padding(.leading, Space.s)
                        .submitLabel(.done)
                        .onSubmit(addWorkout)
                    Button {
                        Haptics.tap()
                        addWorkout()
                    } label: {
                        ButtonLabel(title: L10n.string("program.workout.add"), symbol: "plus")
                    }
                    .buttonStyle(.staerk(.primary, compact: true))
                    .disabled(newWorkoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            TitledSection(title: L10n.string("program.templates")) {
                Card(padding: 0) {
                    ForEach(Array(ProgramCatalog.all.enumerated()), id: \.element.id) { index, blueprint in
                        Button {
                            confirmTemplate = blueprint
                        } label: {
                            ListRow(
                                title: ProgramCatalog.localizedName(blueprint),
                                detail: ProgramCatalog.localizedNotes(blueprint)
                            ) {
                                IconBadge(symbol: "square.stack.3d.up.fill", tint: Palette.accent, size: 36)
                            } trailing: {
                                Chevron()
                            }
                        }
                        .buttonStyle(.pressable)
                        if index < ProgramCatalog.all.count - 1 {
                            RowDivider(inset: 64)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingExercise) { exercise in
            ExerciseEditorView(exercise: exercise)
        }
        .confirmationDialog(
            L10n.string("program.replace.confirm"),
            isPresented: Binding(get: { confirmTemplate != nil }, set: { if !$0 { confirmTemplate = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.string("program.replace"), role: .destructive) {
                if let confirmTemplate {
                    applyTemplate(confirmTemplate)
                }
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        }
        .onAppear {
            programName = program?.name ?? ""
        }
    }

    private func workoutSection(_ workout: WorkoutPlan) -> some View {
        let items = exerciseRows.filter { $0.workoutID == workout.id && !$0.archived }.map { $0.asDomain() }
        return TitledSection(title: workout.name) {
            Button(role: .destructive) {
                Haptics.warn()
                try? app.training.deleteWorkout(id: workout.id)
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.danger)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.9))
            .accessibilityLabel(L10n.string("common.delete.workout"))
        } content: {
            Card(padding: 0) {
                ForEach(items) { exercise in
                    HStack(spacing: 0) {
                        Button {
                            editingExercise = exercise
                        } label: {
                            ListRow(
                                title: exercise.name,
                                detail: "\(exercise.muscleGroup.localizedName) · \(exercise.defaultSets) × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)"
                            ) {
                                EmptyView()
                            } trailing: {
                                EmptyView()
                            }
                        }
                        .buttonStyle(.pressable)
                        .accessibilityHint(L10n.string("common.edit"))

                        Button {
                            Haptics.tap()
                            var copy = exercise
                            copy.archived = true
                            try? app.training.save(copy)
                        } label: {
                            Image(systemName: "eye.slash")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.inkSecondary)
                                .frame(width: 52, height: 52)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableStyle(scale: 0.9))
                        .accessibilityLabel(L10n.string("exercise.hide"))
                        .padding(.trailing, Space.xs)
                    }
                    RowDivider(inset: Space.l)
                }

                Button {
                    let draft = ExerciseDefinition(
                        workoutID: workout.id,
                        name: "",
                        muscleGroup: .legs,
                        sortOrder: (items.map(\.sortOrder).max() ?? 0) + 1
                    )
                    try? app.training.save(draft)
                    editingExercise = draft
                } label: {
                    HStack(spacing: Space.s) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body.weight(.semibold))
                        Text(L10n.string("exercise.add"))
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(Palette.accentInk)
                    .padding(.horizontal, Space.l)
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
        }
    }

    private func saveName() {
        guard var program else { return }
        let trimmed = programName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        program.name = trimmed
        try? app.training.save(program)
    }

    private func addWorkout() {
        guard let program else {
            let created = TrainingProgram(name: L10n.string("program.default.name"), isActive: true)
            try? app.training.save(created)
            let workout = WorkoutPlan(programID: created.id, name: newWorkoutName.trimmingCharacters(in: .whitespaces))
            try? app.training.save(workout)
            newWorkoutName = ""
            return
        }
        let workout = WorkoutPlan(
            programID: program.id,
            name: newWorkoutName.trimmingCharacters(in: .whitespaces),
            sortOrder: (workouts.map(\.sortOrder).max() ?? -1) + 1
        )
        try? app.training.save(workout)
        newWorkoutName = ""
    }

    private func applyTemplate(_ blueprint: ProgramBlueprint) {
        if let existing = program {
            try? app.training.deleteProgram(id: existing.id)
        }
        let packed = ProgramCatalog.materialize(blueprint)
        try? app.training.save(packed.program)
        for workout in packed.workouts { try? app.training.save(workout) }
        for exercise in packed.exercises { try? app.training.save(exercise) }
        try? app.training.save(schedule: packed.schedule)
        Task { await app.refreshReminders() }
        programName = packed.program.name
    }
}

struct ExerciseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var app
    @Query(sort: \WorkoutRecord.sortOrder) private var workoutRows: [WorkoutRecord]
    @State var exercise: ExerciseDefinition

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.string("exercise.name"), text: $exercise.name)
                    Picker(L10n.string("exercise.workout"), selection: $exercise.workoutID) {
                        ForEach(workoutRows.map { $0.asDomain() }) { workout in
                            Text(workout.name).tag(workout.id)
                        }
                    }
                    Picker(L10n.string("exercise.muscle"), selection: $exercise.muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.localizedName).tag(group)
                        }
                    }
                }
                Section {
                    Stepper(L10n.format("exercise.sets", exercise.defaultSets), value: $exercise.defaultSets, in: 1...8)
                    Stepper(L10n.format("exercise.min", exercise.defaultRepsMin), value: $exercise.defaultRepsMin, in: 1...120)
                    Stepper(L10n.format("exercise.max", exercise.defaultRepsMax), value: $exercise.defaultRepsMax, in: 1...180)
                    Picker(L10n.string("exercise.log"), selection: $exercise.logType) {
                        ForEach(LogType.allCases) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                }
                Section(L10n.string("exercise.notes")) {
                    TextField(L10n.string("exercise.notes"), text: $exercise.notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .staerkFormKeyboard()
            .staerkKeyboardDone()
            .navigationTitle(L10n.string("exercise.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save")) {
                        try? app.training.save(exercise)
                        dismiss()
                    }
                    .disabled(exercise.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct ScheduleEditorView: View {
    @Environment(AppContainer.self) private var app
    @Query(sort: \WorkoutRecord.sortOrder) private var workoutRows: [WorkoutRecord]
    @Query private var scheduleRows: [ScheduleRecord]
    @State private var ids: [String?] = Array(repeating: nil, count: 7)

    private var workouts: [WorkoutPlan] { workoutRows.map { $0.asDomain() } }

    var body: some View {
        Screen(keyboardDismiss: .immediately) {
            ScreenHeader(title: L10n.string("schedule.title"), subtitle: L10n.string("schedule.body"))

            Card(padding: 0) {
                ForEach(0..<7, id: \.self) { index in
                    let scheduled = ids[index] != nil
                    HStack(spacing: Space.m) {
                        Text(String(L10n.string(WeekdayLabel.shortKeys[index]).prefix(2)).uppercased())
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(scheduled ? Palette.onAccent : Palette.inkSecondary)
                            .frame(width: 36, height: 36)
                            .background(scheduled ? Palette.accent : Palette.surfaceInset, in: Circle())
                        Text(L10n.string(WeekdayLabel.longKeys[index]))
                            .font(Typeface.rowTitle)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Picker(L10n.string("schedule.day"), selection: Binding(
                            get: { ids[index] ?? "" },
                            set: {
                                Haptics.selection()
                                ids[index] = $0.isEmpty ? nil : $0
                            }
                        )) {
                            Text(L10n.string("schedule.rest")).tag("")
                            ForEach(workouts) { workout in
                                Text(workout.name).tag(workout.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(scheduled ? Palette.accentInk : Palette.inkSecondary)
                        .labelsHidden()
                    }
                    .padding(.horizontal, Space.l)
                    .frame(minHeight: 60)
                    .animation(Motion.snappy, value: scheduled)
                    if index < 6 {
                        RowDivider(inset: 64)
                    }
                }
            }

            PrimaryButton(title: L10n.string("common.save"), symbol: "checkmark") {
                try? app.training.save(schedule: WeeklySchedule(workoutIDs: ids))
                Task { await app.refreshReminders() }
                Haptics.success()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ids = scheduleRows.first?.asDomain().workoutIDs ?? Array(repeating: nil, count: 7)
        }
    }
}

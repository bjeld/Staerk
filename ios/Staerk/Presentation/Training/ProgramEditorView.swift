import SwiftData
import SwiftUI

struct ProgramEditorView: View {
    @Environment(AppContainer.self) private var app
    @Query(sort: \ProgramRecord.sortOrder) private var programRows: [ProgramRecord]
    @Query(sort: \WorkoutRecord.sortOrder) private var workoutRows: [WorkoutRecord]
    @Query(sort: \ExerciseRecord.sortOrder) private var exerciseRows: [ExerciseRecord]
    @State private var programName: String = ""
    @State private var editingExercise: ExerciseDefinition?
    @State private var editingWorkout: WorkoutPlan?
    @State private var confirmTemplate: ProgramBlueprint?
    @State private var newWorkoutName = ""
    @State private var newWorkoutKind: WorkoutKind = .detailed

    private var program: TrainingProgram? { programRows.first { $0.isActive }?.asDomain() ?? programRows.first?.asDomain() }
    private var workouts: [WorkoutPlan] {
        guard let program else { return [] }
        return workoutRows.filter { $0.programID == program.id }.map { $0.asDomain() }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(title: L10n.string("program.edit.title"), subtitle: L10n.string("program.edit.body"))

                GroupedCard {
                    TextField(L10n.string("program.name"), text: Binding(
                        get: { programName.isEmpty ? (program?.name ?? "") : programName },
                        set: { programName = $0 }
                    ))
                    .padding(16)
                    .onSubmit(saveName)
                }

                ForEach(workouts) { workout in
                    workoutSection(workout)
                }

                GroupedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker(L10n.string("program.workout.kind"), selection: $newWorkoutKind) {
                            ForEach(WorkoutKind.allCases) { kind in
                                Text(kind.localizedName).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                        HStack {
                            TextField(L10n.string("program.workout.name"), text: $newWorkoutName)
                            Button(L10n.string("program.workout.add")) { addWorkout() }
                                .disabled(newWorkoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(16)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: L10n.string("program.templates"))
                    ForEach(ProgramCatalog.all) { blueprint in
                        Button {
                            confirmTemplate = blueprint
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ProgramCatalog.localizedName(blueprint))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text((blueprint.workouts.first?.kind ?? .detailed).localizedName)
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(Palette.volt)
                                Text(ProgramCatalog.localizedNotes(blueprint))
                                    .font(.footnote)
                                    .foregroundStyle(Palette.muted)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .staerkKeyboardImmediate()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingExercise) { exercise in
            ExerciseEditorView(exercise: exercise)
        }
        .sheet(item: $editingWorkout) { workout in
            WorkoutEditorView(workout: workout)
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
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel(text: workout.name)
                Spacer()
                Button(L10n.string("common.edit")) { editingWorkout = workout }
                    .font(.subheadline.weight(.semibold))
                Button(role: .destructive) {
                    try? app.training.deleteWorkout(id: workout.id)
                } label: {
                    Image(systemName: "trash")
                }
                .frame(width: 44, height: 44)
            }

            if workout.isCircuit {
                GroupedCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(workout.kind.localizedName)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Palette.volt)
                        if !workout.trimmedLocation.isEmpty {
                            Text(workout.trimmedLocation).font(.subheadline)
                        }
                        if let minutes = workout.targetDurationMinutes {
                            Text(L10n.format("circuit.target.duration", minutes)).font(.footnote).foregroundStyle(Palette.muted)
                        }
                        if let rounds = workout.targetRounds {
                            Text(L10n.format("circuit.target.rounds", rounds)).font(.footnote).foregroundStyle(Palette.muted)
                        }
                        if workout.stations.isEmpty {
                            Text(L10n.string("training.nostations")).foregroundStyle(Palette.muted)
                        } else {
                            ForEach(Array(workout.stations.enumerated()), id: \.element.id) { index, station in
                                Text("\(index + 1). \(station.name)")
                            }
                        }
                    }
                    .padding(16)
                }
            } else {
                ForEach(items) { exercise in
                    GroupedCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(exercise.name).font(.headline)
                            Text("\(exercise.muscleGroup.localizedName) · \(exercise.defaultSets) × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)")
                                .font(.footnote)
                                .foregroundStyle(Palette.muted)
                            HStack {
                                Button(L10n.string("common.edit")) { editingExercise = exercise }
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 44)
                                    .background(RoundedRectangle(cornerRadius: 12).stroke(Palette.hairline))
                                Button(L10n.string("exercise.hide")) {
                                    var copy = exercise
                                    copy.archived = true
                                    try? app.training.save(copy)
                                }
                                .foregroundStyle(Palette.danger)
                                .frame(minHeight: 44)
                                .padding(.horizontal, 12)
                                .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                    }
                }
                Button(L10n.string("exercise.add")) {
                    let draft = ExerciseDefinition(
                        workoutID: workout.id,
                        name: "",
                        muscleGroup: .legs,
                        sortOrder: (items.map(\.sortOrder).max() ?? 0) + 1
                    )
                    try? app.training.save(draft)
                    editingExercise = draft
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 48)
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
            let workout = WorkoutPlan(
                programID: created.id,
                name: newWorkoutName.trimmingCharacters(in: .whitespaces),
                kind: newWorkoutKind
            )
            try? app.training.save(workout)
            newWorkoutName = ""
            editingWorkout = workout
            return
        }
        let workout = WorkoutPlan(
            programID: program.id,
            name: newWorkoutName.trimmingCharacters(in: .whitespaces),
            sortOrder: (workouts.map(\.sortOrder).max() ?? -1) + 1,
            kind: newWorkoutKind
        )
        try? app.training.save(workout)
        newWorkoutName = ""
        editingWorkout = workout
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
            .staerkKeyboardImmediate()
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

struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var app
    @State var workout: WorkoutPlan
    @State private var stationDraft = ""
    @State private var targetRounds: Int
    @State private var targetMinutes: Int

    init(workout: WorkoutPlan) {
        _workout = State(initialValue: workout)
        _targetRounds = State(initialValue: workout.targetRounds ?? 0)
        _targetMinutes = State(initialValue: workout.targetDurationMinutes ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.string("program.workout.name"), text: $workout.name)
                    Picker(L10n.string("program.workout.kind"), selection: $workout.kind) {
                        ForEach(WorkoutKind.allCases) { kind in
                            Text(kind.localizedName).tag(kind)
                        }
                    }
                }
                if workout.isCircuit {
                    Section(L10n.string("program.workout.location")) {
                        TextField(L10n.string("program.workout.location.placeholder"), text: $workout.location)
                    }
                    Section {
                        Stepper(
                            targetMinutes == 0
                                ? L10n.string("program.workout.target.duration.off")
                                : L10n.format("circuit.target.duration", targetMinutes),
                            value: $targetMinutes,
                            in: 0...180,
                            step: 5
                        )
                        Stepper(
                            targetRounds == 0
                                ? L10n.string("program.workout.target.rounds.off")
                                : L10n.format("circuit.target.rounds", targetRounds),
                            value: $targetRounds,
                            in: 0...20
                        )
                    }
                    Section(L10n.string("program.workout.stations")) {
                        ForEach(Array(workout.stations.enumerated()), id: \.element.id) { index, _ in
                            HStack {
                                TextField(
                                    L10n.string("program.workout.station.name"),
                                    text: Binding(
                                        get: { workout.stations[index].name },
                                        set: { workout.stations[index].name = $0 }
                                    )
                                )
                                Button(role: .destructive) {
                                    workout.stations.remove(at: index)
                                    reindexStations()
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .frame(width: 44, height: 44)
                            }
                        }
                        HStack {
                            TextField(L10n.string("program.workout.station.add"), text: $stationDraft)
                            Button(L10n.string("program.workout.add")) {
                                addStation()
                            }
                            .disabled(stationDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .staerkKeyboardImmediate()
            .staerkKeyboardDone()
            .navigationTitle(L10n.string("program.edit.workout"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save")) {
                        save()
                    }
                    .disabled(workout.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func addStation() {
        let name = stationDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        workout.stations.append(
            CircuitStation(name: name, sortOrder: workout.stations.count)
        )
        stationDraft = ""
    }

    private func reindexStations() {
        for index in workout.stations.indices {
            workout.stations[index].sortOrder = index
        }
    }

    private func save() {
        workout.stations = workout.stations
            .map { station in
                var copy = station
                copy.name = station.name.trimmingCharacters(in: .whitespacesAndNewlines)
                return copy
            }
            .filter { !$0.name.isEmpty }
        reindexStations()
        workout.targetRounds = targetRounds > 0 ? targetRounds : nil
        workout.targetDurationMinutes = targetMinutes > 0 ? targetMinutes : nil
        try? app.training.save(workout)
        dismiss()
    }
}

struct ScheduleEditorView: View {
    @Environment(AppContainer.self) private var app
    @Query(sort: \WorkoutRecord.sortOrder) private var workoutRows: [WorkoutRecord]
    @Query private var scheduleRows: [ScheduleRecord]
    @State private var ids: [String?] = Array(repeating: nil, count: 7)

    private var workouts: [WorkoutPlan] { workoutRows.map { $0.asDomain() } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StaerkHeader(title: L10n.string("schedule.title"), subtitle: L10n.string("schedule.body"))
                ForEach(0..<7, id: \.self) { index in
                    GroupedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.string(WeekdayLabel.longKeys[index]))
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            Picker(L10n.string("schedule.day"), selection: Binding(
                                get: { ids[index] ?? "" },
                                set: { ids[index] = $0.isEmpty ? nil : $0 }
                            )) {
                                Text(L10n.string("schedule.rest")).tag("")
                                ForEach(workouts) { workout in
                                    Text(workout.name).tag(workout.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                    }
                }
                PrimaryButton(title: L10n.string("common.save")) {
                    try? app.training.save(schedule: WeeklySchedule(workoutIDs: ids))
                    Task { await app.refreshReminders() }
                    Haptics.success()
                }
            }
            .padding(16)
        }
        .staerkKeyboardImmediate()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ids = scheduleRows.first?.asDomain().workoutIDs ?? Array(repeating: nil, count: 7)
        }
    }
}

import SwiftData
import SwiftUI

struct ProgramView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.order) private var exercises: [Exercise]
    @State private var editing: Exercise?
    @State private var confirmReset = false

    private var visible: [Exercise] {
        exercises.filter { !$0.archived }.sorted { $0.order < $1.order }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(
                    title: "Øvelser",
                    subtitle: "Tilpas programmet til det, jobgymmet faktisk har."
                )

                ForEach(WorkoutLetter.allCases) { letter in
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Program \(letter.rawValue)")
                        let items = visible.filter { $0.workout == letter }
                        ForEach(items, id: \.id) { exercise in
                            exerciseCard(exercise, siblings: items)
                        }
                    }
                }

                PrimaryButton(title: "Tilføj øvelse") {
                    let draft = Exercise(
                        id: StaerkID.make("ex"),
                        name: "",
                        muscleGroup: .legs,
                        workout: .A,
                        defaultSets: 3,
                        defaultRepsMin: 8,
                        defaultRepsMax: 12,
                        logType: .reps,
                        notes: "",
                        order: (visible.filter { $0.workout == .A }.map(\.order).max() ?? 0) + 1
                    )
                    context.insert(draft)
                    try? context.save()
                    editing = draft
                }

                Button("Gendan standardprogram") {
                    confirmReset = true
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.danger)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { editing != nil },
            set: { if !$0 { editing = nil } }
        )) {
            if let editing {
                ExerciseEditorView(exercise: editing)
            }
        }
        .confirmationDialog(
            "Nulstil til standardprogrammet? Dine egne øvelser overskrives.",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Gendan", role: .destructive) {
                Seed.restoreDefaultProgram(in: context)
            }
            Button("Annuller", role: .cancel) {}
        }
    }

    private func exerciseCard(_ exercise: Exercise, siblings: [Exercise]) -> some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name.isEmpty ? "Ny øvelse" : exercise.name)
                            .font(.system(size: 17, weight: .semibold))
                        Text(detail(exercise))
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            move(exercise, dir: -1, siblings: siblings)
                        } label: {
                            Image(systemName: "arrow.up")
                                .frame(width: 36, height: 36)
                                .background(Palette.fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        Button {
                            move(exercise, dir: 1, siblings: siblings)
                        } label: {
                            Image(systemName: "arrow.down")
                                .frame(width: 36, height: 36)
                                .background(Palette.fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .foregroundStyle(.primary)
                    .buttonStyle(.plain)
                }
                HStack(spacing: 8) {
                    Button("Rediger") { editing = exercise }
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Palette.hairline, lineWidth: 1)
                        )
                    Button("Skjul") {
                        exercise.archived = true
                        try? context.save()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.danger)
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                    .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
        .padding(.bottom, 8)
    }

    private func detail(_ exercise: Exercise) -> String {
        let range = "\(exercise.defaultSets) × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)"
        return "\(exercise.muscleGroup.label) · \(range)\(exercise.logType == .seconds ? " sek" : "")"
    }

    private func move(_ exercise: Exercise, dir: Int, siblings: [Exercise]) {
        guard let i = siblings.firstIndex(where: { $0.id == exercise.id }) else { return }
        let j = i + dir
        guard siblings.indices.contains(j) else { return }
        let other = siblings[j]
        let currentOrder = exercise.order
        exercise.order = other.order
        other.order = currentOrder
        try? context.save()
    }
}

struct ExerciseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var exercise: Exercise

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Navn", text: $exercise.name)
                    Picker("Program", selection: $exercise.workoutRaw) {
                        Text("A").tag("A")
                        Text("B").tag("B")
                    }
                    Picker("Muskel", selection: $exercise.muscleGroupRaw) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.label).tag(group.rawValue)
                        }
                    }
                }
                Section {
                    Stepper("Sæt: \(exercise.defaultSets)", value: $exercise.defaultSets, in: 1...8)
                    Stepper("Min: \(exercise.defaultRepsMin)", value: $exercise.defaultRepsMin, in: 1...120)
                    Stepper("Max: \(exercise.defaultRepsMax)", value: $exercise.defaultRepsMax, in: 1...180)
                    Picker("Logning", selection: $exercise.logTypeRaw) {
                        ForEach(LogType.allCases) { type in
                            Text(type.label).tag(type.rawValue)
                        }
                    }
                }
                Section("Noter") {
                    TextField("Noter", text: $exercise.notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Rediger øvelse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuller") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gem") {
                        try? context.save()
                        dismiss()
                    }
                    .disabled(exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

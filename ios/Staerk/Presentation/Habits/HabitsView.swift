import Charts
import SwiftData
import SwiftUI

struct HabitsView: View {
    @Query(sort: \HabitRecord.sortOrder) private var habitRows: [HabitRecord]
    @Query private var entryRows: [HabitEntryRecord]
    @Query(sort: \SessionRecord.dateKey) private var sessionRows: [SessionRecord]
    @Query private var exerciseRows: [ExerciseRecord]
    @State private var cursor = Date()
    @State private var editor: Habit?

    private var habits: [Habit] { habitRows.filter { !$0.archived }.map { $0.asDomain() } }
    private var entries: [HabitEntry] { entryRows.map { $0.asDomain() } }
    private var sessions: [SessionLog] { sessionRows.map { $0.asDomain() } }
    private var today: String { Dates.key() }
    private var week: [String] { Dates.weekKeys() }
    private var trainedDates: Set<String> { Set(sessions.filter(\.completed).map(\.dateKey)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(title: L10n.string("habits.title"), subtitle: L10n.string("habits.subtitle"))

                if habits.isEmpty {
                    GroupedCard {
                        Text(L10n.string("habits.empty"))
                            .foregroundStyle(Palette.muted)
                            .padding(16)
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(habits) { habit in
                            let value = StreakCalculator.habitStreak(
                                habit: habit,
                                entries: entries.filter { $0.habitID == habit.id },
                                sessions: sessions,
                                today: today
                            )
                            GroupedCard {
                                VStack(spacing: 8) {
                                    ProgressRingView(
                                        value: Double(min(value, 14)),
                                        maxValue: 14,
                                        color: Color(hexString: habit.tintHex),
                                        label: "\(value)",
                                        sub: L10n.string("habits.days")
                                    )
                                    Text(habit.name)
                                        .font(.footnote.weight(.semibold))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                            }
                        }
                    }
                    weekCard
                    muscleVolume
                    calendar
                }

                PrimaryButton(title: L10n.string("habits.add")) {
                    editor = Habit(
                        name: "",
                        kind: .boolean,
                        symbol: "checkmark.circle.fill",
                        sortOrder: (habits.map(\.sortOrder).max() ?? -1) + 1
                    )
                }

                if !habits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: L10n.string("habits.manage"))
                        GroupedCard {
                            ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                                HStack {
                                    SymbolCircle(symbol: habit.symbol, tint: Color(hexString: habit.tintHex), size: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(habit.name)
                                        Text(habit.kind.localizedName)
                                            .font(.footnote)
                                            .foregroundStyle(Palette.muted)
                                    }
                                    Spacer()
                                    Button(L10n.string("common.edit")) { editor = habit }
                                        .font(.subheadline.weight(.semibold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                if index < habits.count - 1 {
                                    Divider().overlay(Palette.hairline).padding(.leading, 16)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .staerkKeyboard()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editor) { habit in
            HabitEditorView(habit: habit)
        }
    }

    private var weekCard: some View {
        let score = HabitScoring.weekCompletedCount(
            habits: habits,
            entries: entries,
            trainedDates: trainedDates,
            week: week
        )
        return GroupedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.string("habits.thisweek"))
                        .font(Typeface.card)
                    Spacer()
                    Text("\(score.done)/\(score.total)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Palette.muted)
                }
                ForEach(Array(week.enumerated()), id: \.offset) { index, key in
                    let ratio = HabitScoring.dayRatio(
                        habits: habits,
                        entries: entries.filter { $0.dateKey == key },
                        trained: trainedDates.contains(key),
                        dateKey: key
                    )
                    HStack {
                        Text(key == today
                             ? L10n.format("habits.today.row", L10n.string(WeekdayLabel.shortKeys[index]))
                             : L10n.string(WeekdayLabel.shortKeys[index]))
                            .fontWeight(key == today ? .semibold : .regular)
                        Spacer()
                        Text("\(Int((ratio * 100).rounded()))%")
                            .font(Typeface.title(16))
                            .foregroundStyle(ratio >= 1 ? Palette.volt : Palette.muted)
                    }
                    .font(.body)
                }
            }
            .padding(16)
        }
    }

    private var muscleVolume: some View {
        let muscleMap = Dictionary(uniqueKeysWithValues: exerciseRows.map { ($0.id, MuscleGroup(rawValue: $0.muscleGroupRaw) ?? .legs) })
        let volume = ProgressionCalculator.weeklySetVolume(
            sessions: sessions,
            weekStart: week.first ?? today,
            weekEnd: week.last ?? today,
            muscleOf: { muscleMap[$0] }
        )
        let data = MuscleGroup.allCases.map { MuscleVolume(id: $0.rawValue, name: $0.localizedName, sets: volume[$0] ?? 0) }
        let empty = data.allSatisfy { $0.sets == 0 }

        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: L10n.string("habits.volume"))
            GroupedCard {
                if empty {
                    Text(L10n.string("habits.volume.empty"))
                        .foregroundStyle(Palette.muted)
                        .padding(16)
                } else {
                    Chart(data) { item in
                        BarMark(x: .value("M", item.name), y: .value("S", item.sets))
                            .foregroundStyle(Palette.volt)
                    }
                    .frame(height: 180)
                    .padding(16)
                }
            }
        }
    }

    private var calendar: some View {
        let cells = Dates.monthGrid(cursor)
        let grouped = Dictionary(grouping: entries, by: \.dateKey)
        return GroupedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button { cursor = Dates.calendar.date(byAdding: .month, value: -1, to: cursor) ?? cursor } label: {
                        Image(systemName: "chevron.left").frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text(Dates.monthTitle(cursor)).font(.headline)
                    Spacer()
                    Button { cursor = Dates.calendar.date(byAdding: .month, value: 1, to: cursor) ?? cursor } label: {
                        Image(systemName: "chevron.right").frame(width: 44, height: 44)
                    }
                }
                .foregroundStyle(.primary)

                HStack {
                    ForEach(WeekdayLabel.shortKeys, id: \.self) { key in
                        Text(L10n.string(key))
                            .font(.caption2)
                            .foregroundStyle(Palette.muted)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, key in
                        if let key {
                            let ratio = HabitScoring.dayRatio(
                                habits: habits,
                                entries: grouped[key] ?? [],
                                trained: trainedDates.contains(key),
                                dateKey: key
                            )
                            Text(dayNumber(key))
                                .font(.caption.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(Palette.volt.opacity(ratio == 0 ? 0.08 : 0.15 + ratio * 0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    if key == today {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.primary, lineWidth: 2)
                                    }
                                }
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func dayNumber(_ key: String) -> String {
        String(Int(key.suffix(2)) ?? 0)
    }
}

private struct MuscleVolume: Identifiable {
    var id: String
    var name: String
    var sets: Int
}

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var app
    @State var habit: Habit
    @State private var reminderDate: Date
    @State private var confirmDelete = false

    init(habit: Habit) {
        _habit = State(initialValue: habit)
        _reminderDate = State(initialValue: Dates.date(fromHHMM: habit.reminderTime))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("habit.section.identity")) {
                    TextField(L10n.string("habit.name"), text: $habit.name)
                    Picker(L10n.string("habit.kind"), selection: $habit.kind) {
                        ForEach(HabitKind.allCases) { kind in
                            Text(kind.localizedName).tag(kind)
                        }
                    }
                    TextField(L10n.string("habit.symbol"), text: $habit.symbol)
                        .textInputAutocapitalization(.never)
                    if habit.kind == .counter {
                        Stepper(L10n.format("habit.goal", habit.goal), value: $habit.goal, in: 1...50)
                    }
                }
                Section(L10n.string("habit.section.schedule")) {
                    WeekdayPicker(selection: $habit.weekdays)
                }
                Section(L10n.string("habit.section.reminder")) {
                    Toggle(L10n.string("habit.reminder"), isOn: $habit.reminderEnabled)
                    if habit.reminderEnabled {
                        DatePicker(L10n.string("habit.time"), selection: $reminderDate, displayedComponents: .hourAndMinute)
                    }
                }
                Section(L10n.string("habit.section.notes")) {
                    TextField(L10n.string("habit.notes"), text: $habit.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                if appContains(habit) {
                    Section {
                        Button(L10n.string("habit.delete"), role: .destructive) {
                            confirmDelete = true
                        }
                    }
                }
            }
            .staerkKeyboardImmediate()
            .staerkKeyboardDone()
            .navigationTitle(habit.name.isEmpty ? L10n.string("habit.new") : L10n.string("habit.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save")) { save() }
                        .disabled(habit.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(L10n.string("habit.delete.confirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(L10n.string("habit.delete"), role: .destructive) {
                    try? app.habits.delete(id: habit.id)
                    Task { await app.refreshReminders() }
                    dismiss()
                }
                Button(L10n.string("common.cancel"), role: .cancel) {}
            }
        }
        .presentationDetents([.large])
    }

    private func appContains(_ habit: Habit) -> Bool {
        (try? app.habits.habit(id: habit.id)) != nil
    }

    private func save() {
        habit.reminderTime = Dates.hhmm(from: reminderDate)
        try? app.habits.save(habit)
        Task { await app.refreshReminders() }
        Haptics.success()
        dismiss()
    }
}

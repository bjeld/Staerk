import SwiftData
import SwiftUI

struct HabitsView: View {
    var embedded = false

    @Query(sort: \HabitRecord.sortOrder) private var habitRows: [HabitRecord]
    @Query private var entryRows: [HabitEntryRecord]
    @Query(sort: \SessionRecord.dateKey) private var sessionRows: [SessionRecord]
    @Query private var exerciseRows: [ExerciseRecord]
    @Query private var scheduleRows: [ScheduleRecord]
    @State private var cursor = Date()
    @State private var editor: Habit?

    private var habits: [Habit] { habitRows.filter { !$0.archived }.map { $0.asDomain() } }
    private var entries: [HabitEntry] { entryRows.map { $0.asDomain() } }
    private var sessions: [SessionLog] { sessionRows.map { $0.asDomain() } }
    private var today: String { Dates.key() }
    private var week: [String] { Dates.weekKeys() }
    private var trainedDates: Set<String> { Set(sessions.filter(\.completed).map(\.dateKey)) }
    private var schedule: WeeklySchedule { scheduleRows.first?.asDomain() ?? WeeklySchedule() }
    private var showsCircuitProgress: Bool { sessions.contains(where: \.isCircuit) }

    var body: some View {
        Screen {
            ScreenHeader(title: L10n.string("habits.title"), subtitle: L10n.string("habits.subtitle")) {
                IconButton(symbol: "plus", label: L10n.string("habits.add"), filled: true) {
                    addHabit()
                }
            }

            if habits.isEmpty {
                Card {
                    EmptyState(symbol: "sparkles", message: L10n.string("habits.empty"))
                        .padding(-Space.l)
                        .padding(.bottom, Space.l)
                    PrimaryButton(title: L10n.string("habits.add"), symbol: "plus") {
                        addHabit()
                    }
                }
            } else {
                weekCard
                habitList
                if showsCircuitProgress {
                    CircuitProgressCard(
                        summary: CircuitProgress.summary(
                            sessions: sessions,
                            schedule: schedule,
                            today: today,
                            weekKeys: week
                        )
                    )
                }
                muscleVolume
                calendar
            }
        }
        .navigationTitle(embedded ? "" : L10n.string("habits.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(embedded ? .automatic : .hidden, for: .navigationBar)
        .sheet(item: $editor) { habit in
            HabitEditorView(habit: habit)
        }
    }

    private func addHabit() {
        editor = Habit(
            name: "",
            kind: .boolean,
            symbol: "checkmark.circle.fill",
            sortOrder: (habits.map(\.sortOrder).max() ?? -1) + 1
        )
    }

    // MARK: Week

    private var weekCard: some View {
        let score = HabitScoring.weekCompletedCount(
            habits: habits,
            entries: entries,
            trainedDates: trainedDates,
            week: week
        )
        let ratios = week.map { key in
            HabitScoring.dayRatio(
                habits: habits,
                entries: entries.filter { $0.dateKey == key },
                trained: trainedDates.contains(key),
                dateKey: key
            )
        }
        let percent = score.total > 0 ? Int((Double(score.done) / Double(score.total) * 100).rounded()) : 0
        return Card(padding: Space.xl) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Eyebrow(text: L10n.string("habits.thisweek"))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(score.done)")
                            .font(Typeface.hero)
                            .monospacedDigit()
                            .foregroundStyle(Palette.ink)
                            .contentTransition(.numericText(value: Double(score.done)))
                        Text(verbatim: "/\(score.total)")
                            .font(Typeface.title(24))
                            .monospacedDigit()
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    Text(L10n.string("habits.week.caption"))
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                Pill(text: "\(percent)%", tint: Palette.accent, filled: percent >= 100)
            }
            WeekBars(values: ratios, todayIndex: week.firstIndex(of: today))
                .padding(.top, Space.xl)
        }
    }

    // MARK: Habit list

    private var habitList: some View {
        TitledSection(title: L10n.string("habits.manage")) {
            Card(padding: 0) {
                ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                    Button {
                        editor = habit
                    } label: {
                        habitRow(habit)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityHint(L10n.string("common.edit"))
                    if index < habits.count - 1 {
                        RowDivider(inset: 70)
                    }
                }
            }
        }
    }

    private func habitRow(_ habit: Habit) -> some View {
        let habitEntries = entries.filter { $0.habitID == habit.id }
        let streak = StreakCalculator.habitStreak(
            habit: habit,
            entries: habitEntries,
            sessions: sessions,
            today: today
        )
        let byDay = Dictionary(uniqueKeysWithValues: habitEntries.map { ($0.dateKey, $0) })
        let tint = Color(hexString: habit.tintHex)
        return HStack(spacing: Space.m) {
            IconBadge(symbol: habit.symbol, tint: tint, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(Typeface.rowTitle)
                    .foregroundStyle(Palette.ink)
                    .staerkWrappingText()
                HStack(spacing: Space.xs) {
                    Image(systemName: "flame.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(streak > 0 ? Palette.energy : Palette.inkTertiary)
                    Text(verbatim: "\(streak)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(streak > 0 ? Palette.ink : Palette.inkTertiary)
                    Text(L10n.string("habits.streak.caption"))
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 5) {
                ForEach(week, id: \.self) { key in
                    let applies = habit.applies(onKey: key)
                    let done = applies && HabitScoring.isComplete(habit: habit, entry: byDay[key], trained: trainedDates.contains(key))
                    Circle()
                        .fill(done ? tint : (applies ? Palette.track : Color.clear))
                        .overlay {
                            if !applies {
                                Circle().strokeBorder(Palette.track, lineWidth: 1.5)
                            }
                        }
                        .overlay {
                            if key == today {
                                Circle().strokeBorder(Palette.ink.opacity(done ? 0 : 0.5), lineWidth: 1.5)
                            }
                        }
                        .frame(width: 9, height: 9)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.m + 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: Volume

    @ViewBuilder
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
        let total = data.reduce(0) { $0 + $1.sets }
        if empty && showsCircuitProgress {
            EmptyView()
        } else {
            TitledSection(title: L10n.string("habits.volume"), detail: empty ? nil : "\(total)") {
                Card(padding: empty ? 0 : Space.xl) {
                    if empty {
                        EmptyState(symbol: "chart.bar", message: L10n.string("habits.volume.empty"))
                    } else {
                        BarList(items: data.map { BarListItem(id: $0.id, label: $0.name, value: $0.sets) })
                    }
                }
            }
        }
    }

    // MARK: Calendar

    private var calendar: some View {
        let cells = Dates.monthGrid(cursor)
        let grouped = Dictionary(grouping: entries, by: \.dateKey)
        return TitledSection(title: Dates.monthTitle(cursor)) {
            HStack(spacing: Space.xs) {
                monthButton("chevron.left", offset: -1)
                monthButton("chevron.right", offset: 1)
            }
        } content: {
            Card(padding: Space.l) {
                HStack(spacing: 6) {
                    ForEach(WeekdayLabel.shortKeys, id: \.self) { key in
                        Text(String(L10n.string(key).prefix(1)).uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Palette.inkTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, Space.s)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, key in
                        if let key {
                            let ratio = HabitScoring.dayRatio(
                                habits: habits,
                                entries: grouped[key] ?? [],
                                trained: trainedDates.contains(key),
                                dateKey: key
                            )
                            heatCell(key: key, ratio: ratio)
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }

    private func monthButton(_ symbol: String, offset: Int) -> some View {
        Button {
            Haptics.selection()
            withAnimation(Motion.snappy) {
                cursor = Dates.calendar.date(byAdding: .month, value: offset, to: cursor) ?? cursor
            }
        } label: {
            CircleIcon(symbol: symbol, size: 32, tint: Palette.inkSecondary)
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .frame(width: 36)
    }

    private func heatCell(key: String, ratio: Double) -> some View {
        let isFuture = key > today
        let strong = ratio >= 0.6
        return RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(ratio > 0 ? Palette.accent.opacity(0.22 + ratio * 0.78) : Palette.surfaceInset)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Text(dayNumber(key))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(isFuture ? Palette.inkTertiary : (strong ? Palette.onAccent : Palette.ink))
                    .fixedSize()
            }
            .overlay {
                if key == today {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Palette.ink, lineWidth: 1.5)
                }
            }
            .accessibilityLabel(Dates.prettyLong(key: key))
            .accessibilityValue("\(Int((ratio * 100).rounded()))%")
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
                Section {
                    HStack(spacing: Space.m) {
                        IconBadge(symbol: habit.symbol, tint: Color(hexString: habit.tintHex), size: 52, style: .solid)
                        VStack(alignment: .leading, spacing: Space.xxs) {
                            Text(habit.name.isEmpty ? L10n.string("habit.new") : habit.name)
                                .font(Typeface.cardTitle)
                                .foregroundStyle(habit.name.isEmpty ? Palette.inkTertiary : Palette.ink)
                                .lineLimit(1)
                            Text(habit.kind.localizedName)
                                .font(.subheadline)
                                .foregroundStyle(Palette.inkSecondary)
                        }
                    }
                    .padding(.vertical, Space.xs)
                    .animation(Motion.snappy, value: habit.symbol)
                }
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
                        .padding(.vertical, Space.xs)
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
            .staerkFormKeyboard()
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

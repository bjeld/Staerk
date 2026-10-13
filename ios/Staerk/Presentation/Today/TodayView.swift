import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(AppContainer.self) private var app
    @Environment(HealthKitService.self) private var health
    @Query(sort: \HabitRecord.sortOrder) private var habitRows: [HabitRecord]
    @Query private var entryRows: [HabitEntryRecord]
    @Query private var settingsRows: [SettingsRecord]
    @Query(sort: \SessionRecord.dateKey, order: .reverse) private var sessionRows: [SessionRecord]
    @Query private var workoutRows: [WorkoutRecord]
    @Query private var scheduleRows: [ScheduleRecord]
    @Query(filter: #Predicate<ExerciseRecord> { !$0.archived }, sort: \ExerciseRecord.sortOrder)
    private var exerciseRows: [ExerciseRecord]

    @State private var celebration = 0

    private var settings: UserSettings { settingsRows.first?.asDomain() ?? UserSettings() }
    private var habits: [Habit] { habitRows.filter { !$0.archived }.map { $0.asDomain() } }
    private var todayKey: String { Dates.key() }
    private var todayEntries: [HabitEntry] {
        entryRows.filter { $0.dateKey == todayKey }.map { $0.asDomain() }
    }
    private var sessions: [SessionLog] { sessionRows.map { $0.asDomain() } }
    private var schedule: WeeklySchedule { scheduleRows.first?.asDomain() ?? WeeklySchedule() }
    private var workouts: [WorkoutPlan] { workoutRows.map { $0.asDomain() } }
    private var dayPlan: DayPlan { ScheduleResolver.plan(on: Date(), schedule: schedule, workouts: workouts) }
    private var todaysHabits: [Habit] { habits.filter { $0.applies(onKey: todayKey) } }
    private var trainedToday: Bool {
        sessions.contains { $0.dateKey == todayKey && $0.completed }
    }
    private var todaySession: SessionLog? {
        sessions.first { $0.dateKey == todayKey && $0.completed }
    }

    private var ratio: Double {
        HabitScoring.dayRatio(habits: todaysHabits, entries: todayEntries, trained: trainedToday, dateKey: todayKey)
    }

    private var doneCount: Int {
        HabitScoring.dayScore(habits: todaysHabits, entries: todayEntries, trained: trainedToday, dateKey: todayKey)
    }

    private var isDayComplete: Bool { ratio >= 1 }

    private var weekMarks: [String: Double] {
        let week = Dates.weekKeys()
        let grouped = Dictionary(grouping: entryRows.map { $0.asDomain() }, by: \.dateKey)
        var map: [String: Double] = [:]
        let trained = Set(sessions.filter(\.completed).map(\.dateKey))
        for key in week {
            map[key] = HabitScoring.dayRatio(
                habits: habits,
                entries: grouped[key] ?? [],
                trained: trained.contains(key),
                dateKey: key
            )
        }
        return map
    }

    var body: some View {
        Screen {
            ScreenHeader(eyebrow: Dates.prettyLong(Date()), title: greeting)

            WeekStrip(today: todayKey, marks: weekMarks)

            heroCard

            habitsSection

            activitySection
        }
        .navigationTitle(L10n.string("tab.today"))
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: isDayComplete) { wasComplete, complete in
            if complete && !wasComplete {
                celebration += 1
                Haptics.celebrate()
            }
        }
        .task {
            if health.didRequestAuthorization {
                await health.refreshToday()
            }
        }
        .refreshable {
            if health.didRequestAuthorization {
                await health.refreshToday()
            }
        }
    }

    private var greeting: String {
        let name = settings.trimmedName
        if name.isEmpty { return Dates.greeting() }
        return L10n.format("greeting.named", Dates.greeting(), name)
    }

    // MARK: Hero

    private var heroCard: some View {
        Card(padding: Space.xl) {
            HStack(spacing: Space.xl) {
                HeroRing(progress: ratio, size: 132, lineWidth: 15) {
                    ringCenter
                }
                .keyframeAnimator(initialValue: 1.0, trigger: celebration) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    SpringKeyframe(1.07, duration: 0.22, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.string("today.habits"))
                .accessibilityValue("\(Int((ratio * 100).rounded()))%")

                VStack(alignment: .leading, spacing: Space.xs) {
                    Eyebrow(text: L10n.string("tab.today"))
                    Text(progressTitle)
                        .font(Typeface.cardTitle)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .contentTransition(.numericText())
                    if let progressDetail {
                        Text(progressDetail)
                            .font(.subheadline)
                            .foregroundStyle(isDayComplete ? Palette.accentInk : Palette.inkSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(Motion.snappy, value: doneCount)
            }

            RowDivider()
                .padding(.vertical, Space.xl)

            planRow

            if dayPlan.isTrainingDay {
                NavigationLink {
                    if let todaySession {
                        SessionDetailView(sessionID: todaySession.id)
                    } else {
                        SessionView()
                    }
                } label: {
                    ButtonLabel(
                        title: todaySession == nil ? L10n.string("today.start.workout") : L10n.string("today.see.workout"),
                        symbol: todaySession == nil ? "play.fill" : nil
                    )
                }
                .buttonStyle(todaySession == nil ? .staerkPrimary : .staerkSecondary)
                .padding(.top, Space.l)
            }
        }
    }

    @ViewBuilder
    private var ringCenter: some View {
        if isDayComplete {
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(Palette.accentInk)
                .symbolEffect(.bounce, value: celebration)
                .transition(.scale.combined(with: .opacity))
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(Int((ratio * 100).rounded()))")
                    .font(Typeface.display(40))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: ratio))
                Text(verbatim: "%")
                    .font(Typeface.title(18))
                    .foregroundStyle(Palette.inkSecondary)
            }
            .foregroundStyle(Palette.ink)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .animation(Motion.snappy, value: ratio)
        }
    }

    private var progressTitle: String {
        if isDayComplete { return L10n.string("today.complete") }
        return L10n.format("today.habits.count", doneCount, todaysHabits.count)
    }

    private var progressDetail: String? {
        if todaysHabits.isEmpty { return nil }
        if isDayComplete { return L10n.format("today.habits.count", doneCount, todaysHabits.count) }
        return L10n.format("today.left", todaysHabits.count - doneCount)
    }

    private var planRow: some View {
        HStack(alignment: .top, spacing: Space.m) {
            IconBadge(
                symbol: dayPlan.isTrainingDay ? "dumbbell.fill" : "figure.walk",
                tint: Palette.accent,
                size: 44,
                style: todaySession != nil ? .solid : .soft
            )
            VStack(alignment: .leading, spacing: Space.xxs) {
                Eyebrow(
                    text: dayPlan.isTrainingDay ? L10n.string("today.train") : L10n.string("today.rest"),
                    color: Palette.accentInk
                )
                Text(heroTitle)
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
                if !heroSubtitle.isEmpty {
                    Text(heroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var heroTitle: String {
        if let workout = dayPlan.workout {
            if todaySession != nil {
                return L10n.format("today.workout.done", workout.name)
            }
            return workout.name
        }
        return L10n.string("today.rest.title")
    }

    private var heroSubtitle: String {
        if dayPlan.isTrainingDay {
            let names = exerciseRows
                .filter { $0.workoutID == dayPlan.workout?.id }
                .map { $0.asDomain().muscleGroup.localizedName }
            let unique = Array(NSOrderedSet(array: names)) as? [String] ?? names
            return unique.joined(separator: " · ")
        }
        return L10n.string("today.rest.body")
    }

    // MARK: Habits

    @ViewBuilder
    private var habitsSection: some View {
        TitledSection(
            title: L10n.string("today.habits"),
            detail: todaysHabits.isEmpty ? nil : "\(doneCount)/\(todaysHabits.count)"
        ) {
            Card(padding: 0) {
                if todaysHabits.isEmpty {
                    EmptyState(symbol: "sparkles", message: L10n.string("today.nohabits"))
                } else {
                    ForEach(Array(todaysHabits.enumerated()), id: \.element.id) { index, habit in
                        habitRow(habit)
                        if index < todaysHabits.count - 1 {
                            RowDivider(inset: 72)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func habitRow(_ habit: Habit) -> some View {
        let entry = todayEntries.first { $0.habitID == habit.id } ?? HabitEntry(habitID: habit.id, dateKey: todayKey)
        switch habit.kind {
        case .boolean, .workout:
            HabitCheckRow(
                title: habit.name,
                hint: habit.notes,
                tint: Color(hexString: habit.tintHex),
                symbol: habit.symbol,
                isOn: HabitScoring.isComplete(habit: habit, entry: entry, trained: trainedToday)
            ) {
                toggle(habit, entry: entry)
            }
        case .counter:
            HabitCounterRow(
                title: habit.name,
                tint: Color(hexString: habit.tintHex),
                symbol: habit.symbol,
                value: entry.countValue,
                goal: habit.goal
            ) { next in
                var updated = entry
                updated.countValue = next
                try? app.habits.upsert(updated)
            }
        }
    }

    private func toggle(_ habit: Habit, entry: HabitEntry) {
        var updated = entry
        if habit.kind == .workout && trainedToday && updated.boolValue {
            updated.boolValue = false
        } else {
            updated.boolValue.toggle()
        }
        try? app.habits.upsert(updated)
    }

    // MARK: Activity

    private var activitySection: some View {
        TitledSection(title: L10n.string("today.activity")) {
            if health.showsPermissionPrompt {
                permissionPrompt
            } else if !health.isAvailable {
                Card(padding: 0) {
                    EmptyState(symbol: "heart.slash", message: L10n.string("health.unavailable"))
                }
            } else {
                activityMetrics
            }
        }
    }

    private var permissionPrompt: some View {
        Card {
            HStack(alignment: .top, spacing: Space.m) {
                IconBadge(symbol: "heart.fill", tint: Palette.health, size: 40)
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(L10n.string("health.title"))
                        .font(.headline)
                        .foregroundStyle(Palette.ink)
                    Text(L10n.string("health.prompt"))
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            SecondaryButton(title: L10n.string("health.allow")) {
                Task { await health.requestAccess() }
            }
            .padding(.top, Space.l)
        }
    }

    private var activityMetrics: some View {
        VStack(spacing: Space.m) {
            if health.showsDeniedHelp {
                Card(padding: 0) {
                    EmptyState(symbol: "heart.slash", message: L10n.string("health.denied"))
                }
            }
            HStack(spacing: Space.m) {
                MetricTile(symbol: "figure.walk", tint: Palette.steps, value: stepsLabel, unit: nil, label: L10n.string("health.steps"))
                MetricTile(symbol: "flame.fill", tint: Palette.energy, value: energyLabel, unit: "kcal", label: L10n.string("health.energy"))
                MetricTile(symbol: "location.fill", tint: Palette.distance, value: distanceLabel, unit: "km", label: L10n.string("health.distance"))
            }
            if !health.today.workouts.isEmpty {
                Card(padding: 0) {
                    ForEach(Array(health.today.workouts.enumerated()), id: \.element.id) { index, workout in
                        ListRow(
                            title: L10n.string(workout.kind.titleKey),
                            detail: L10n.format("health.minutes", workout.durationMinutes)
                        ) {
                            IconBadge(symbol: workout.kind.symbol, tint: Palette.accent, size: 36)
                        } trailing: {
                            Text(workout.start, format: .dateTime.hour().minute())
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Palette.inkSecondary)
                        }
                        if index < health.today.workouts.count - 1 {
                            RowDivider(inset: 64)
                        }
                    }
                }
            }
        }
    }

    private var stepsLabel: String {
        guard let steps = health.today.steps else { return "—" }
        return Int(steps.rounded()).formatted(.number)
    }

    private var energyLabel: String {
        guard let kcal = health.today.activeEnergyKcal else { return "—" }
        return "\(Int(kcal.rounded()))"
    }

    private var distanceLabel: String {
        guard let km = health.today.distanceKm else { return "—" }
        return String(format: "%.1f", km)
    }
}

// MARK: - Habit rows

private struct HabitCheckRow: View {
    var title: String
    var hint: String
    var tint: Color
    var symbol: String
    var isOn: Bool
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            withAnimation(Motion.bouncy) {
                action()
            }
            if !isOn { Haptics.success() }
        } label: {
            ListRow(title: title, detail: hint) {
                IconBadge(symbol: symbol, tint: tint, size: 42, style: isOn ? .solid : .soft)
                    .animation(Motion.bouncy, value: isOn)
            } trailing: {
                CompletionCheck(isOn: isOn, tint: tint)
                    .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? String(localized: "a11y.done") : String(localized: "a11y.todo"))
    }
}

private struct HabitCounterRow: View {
    var title: String
    var tint: Color
    var symbol: String
    var value: Int
    var goal: Int
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: Space.m) {
            IconBadge(symbol: symbol, tint: tint, size: 42, style: value >= goal ? .solid : .soft)
                .animation(Motion.bouncy, value: value >= goal)
            VStack(alignment: .leading, spacing: Space.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(Typeface.rowTitle)
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: Space.xs)
                    Text(verbatim: "\(value)/\(goal)")
                        .font(.footnote.weight(.semibold).monospacedDigit())
                        .foregroundStyle(value >= goal ? tint.legible : Palette.inkSecondary)
                        .contentTransition(.numericText(value: Double(value)))
                }
                SegmentedProgress(value: value, goal: goal, tint: tint)
            }
            .accessibilityElement(children: .combine)
            CounterControl(value: value, goal: goal, onChange: onChange)
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.m + 1)
        .animation(Motion.snappy, value: value)
    }
}

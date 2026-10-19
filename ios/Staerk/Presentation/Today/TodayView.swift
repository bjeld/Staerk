import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(AppContainer.self) private var app
    @Environment(HealthKitService.self) private var health
    @Query(sort: \HabitRecord.sortOrder) private var habitRows: [HabitRecord]
    @Query private var entryRows: [HabitEntryRecord]
    @Query private var settingsRows: [SettingsRecord]
    @Query(sort: \SessionRecord.dateKey, order: .reverse) private var sessionRows: [SessionRecord]
    @Query private var programRows: [ProgramRecord]
    @Query private var workoutRows: [WorkoutRecord]
    @Query private var scheduleRows: [ScheduleRecord]
    @Query(filter: #Predicate<ExerciseRecord> { !$0.archived }, sort: \ExerciseRecord.sortOrder)
    private var exerciseRows: [ExerciseRecord]

    private var settings: UserSettings { settingsRows.first?.asDomain() ?? UserSettings() }
    private var habits: [Habit] { habitRows.filter { !$0.archived }.map { $0.asDomain() } }
    private var todayKey: String { Dates.key() }
    private var todayEntries: [HabitEntry] {
        entryRows.filter { $0.dateKey == todayKey }.map { $0.asDomain() }
    }
    private var sessions: [SessionLog] { sessionRows.map { $0.asDomain() } }
    private var schedule: WeeklySchedule { scheduleRows.first?.asDomain() ?? WeeklySchedule() }
    private var program: TrainingProgram? {
        programRows.first { $0.isActive }?.asDomain() ?? programRows.first?.asDomain()
    }
    private var workouts: [WorkoutPlan] {
        guard let program else { return [] }
        return workoutRows.filter { $0.programID == program.id }.map { $0.asDomain() }
    }
    private var hasWorkouts: Bool { !workouts.isEmpty }
    private var visibleHabits: [Habit] {
        HabitScoring.excludingDanglingWorkoutHabits(habits, hasWorkouts: hasWorkouts)
    }
    private var dayStatus: DayTrainingStatus {
        ScheduleResolver.status(on: Date(), schedule: schedule, workouts: workouts)
    }
    private var todaysHabits: [Habit] { visibleHabits.filter { $0.applies(onKey: todayKey) } }
    private var trainedToday: Bool {
        hasWorkouts && sessions.contains { $0.dateKey == todayKey && $0.completed }
    }
    private var todaySession: SessionLog? {
        sessions.first { $0.dateKey == todayKey && $0.completed }
    }
    private var remainingHabits: Int { max(0, todaysHabits.count - habitsDoneToday) }

    private var ratio: Double {
        HabitScoring.dayRatio(habits: todaysHabits, entries: todayEntries, trained: trainedToday, dateKey: todayKey)
    }

    private var weekMarks: [String: Double] {
        let week = Dates.weekKeys()
        let grouped = Dictionary(grouping: entryRows.map { $0.asDomain() }, by: \.dateKey)
        var map: [String: Double] = [:]
        let trained = Set(sessions.filter(\.completed).map(\.dateKey))
        for key in week {
            map[key] = HabitScoring.dayRatio(
                habits: visibleHabits,
                entries: grouped[key] ?? [],
                trained: hasWorkouts && trained.contains(key),
                dateKey: key
            )
        }
        return map
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(
                    title: greeting,
                    subtitle: Dates.prettyLong(Date())
                )

                GroupedCard {
                    WeekStripView(today: todayKey, marks: weekMarks)
                }

                habitHeroCard
                if dayStatus.showsStatus {
                    trainingStatusCard
                }
                healthCard

                if !todaysHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(L10n.string("today.habits"))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.muted)
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .staerkWrappingText()
                            Spacer(minLength: 8)
                            Text(L10n.format("today.habits.count", habitsDoneToday, todaysHabits.count))
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(.horizontal, 4)
                        TwoColumnFlow(items: todaysHabits) { habit in
                            habitCard(habit)
                        }
                    }
                } else {
                    GroupedCard {
                        Text(L10n.string("today.nohabits"))
                            .font(.body)
                            .foregroundStyle(Palette.muted)
                            .padding(16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .staerkKeyboard()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(L10n.string("tab.today"))
        .toolbar(.hidden, for: .navigationBar)
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

    private var habitHeroCard: some View {
        GroupedCard {
            HStack(alignment: .center, spacing: 16) {
                CompletionRing(
                    progress: ratio,
                    label: "\(Int((ratio * 100).rounded()))%",
                    caption: L10n.string("today.complete")
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.string("today.summary.eyebrow"))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Palette.volt)
                        .textCase(.uppercase)
                    Text(L10n.format("today.habits.summary", habitsDoneToday, todaysHabits.count))
                        .font(Typeface.card)
                        .staerkWrappingText()
                    Text(habitHeroSubtitle)
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                        .staerkWrappingText()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
    }

    private var trainingStatusCard: some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dayStatus.isTrainingDay ? L10n.string("today.train") : L10n.string("today.rest"))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Palette.volt)
                        .textCase(.uppercase)
                    Text(heroTitle)
                        .font(Typeface.card)
                        .staerkWrappingText()
                    Text(heroSubtitle)
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                        .staerkWrappingText()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if dayStatus.isTrainingDay {
                    NavigationLink {
                        if let todaySession {
                            SessionDetailView(sessionID: todaySession.id)
                        } else {
                            SessionView()
                        }
                    } label: {
                        Text(todayCTA)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Palette.voltForeground)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 56)
                            .background(Palette.volt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    private var habitHeroSubtitle: String {
        if todaysHabits.isEmpty {
            return L10n.string("today.habits.none")
        }
        if remainingHabits == 0 {
            return L10n.string("today.habits.cleared")
        }
        return L10n.format("today.habits.remaining", remainingHabits)
    }

    private var heroTitle: String {
        if let workout = dayStatus.workout {
            if todaySession != nil {
                return L10n.format("today.workout.done", workout.name)
            }
            return workout.name
        }
        return L10n.string("today.rest.title")
    }

    private var heroSubtitle: String {
        if let workout = dayStatus.workout, workout.isCircuit {
            if !workout.trimmedLocation.isEmpty {
                return workout.trimmedLocation
            }
            return L10n.string("workout.kind.circuit")
        }
        if let workout = dayStatus.workout {
            let names = exerciseRows
                .filter { $0.workoutID == workout.id }
                .map { $0.asDomain().muscleGroup.localizedName }
            let unique = Array(NSOrderedSet(array: names)) as? [String] ?? names
            return unique.joined(separator: " · ")
        }
        return L10n.string("today.rest.body")
    }

    private var todayCTA: String {
        if todaySession != nil {
            return L10n.string("today.see.workout")
        }
        if dayStatus.workout?.isCircuit == true {
            return L10n.string("training.start.circuit")
        }
        return L10n.string("today.start.workout")
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: L10n.string("today.activity"))
            GroupedCard {
                if health.showsPermissionPrompt {
                    permissionPrompt
                } else if !health.isAvailable {
                    Text(L10n.string("health.unavailable"))
                        .font(.body)
                        .foregroundStyle(Palette.muted)
                        .padding(16)
                } else {
                    activityMetrics
                }
            }
        }
    }

    private var permissionPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color(hex: 0xFF3B5C))
                Text(L10n.string("health.title"))
                    .font(.headline)
            }
            Text(L10n.string("health.prompt"))
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
                .staerkWrappingText()
            PrimaryButton(title: L10n.string("health.allow")) {
                Task { await health.requestAccess() }
            }
        }
        .padding(16)
    }

    private var activityMetrics: some View {
        VStack(spacing: 0) {
            if health.showsDeniedHelp {
                Text(L10n.string("health.denied"))
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                    .padding(16)
                Divider().overlay(Palette.hairline)
            }
            metricRow(symbol: "figure.walk", tint: Color(hex: 0xFF3B5C), title: L10n.string("health.steps"), value: stepsLabel)
            Divider().overlay(Palette.hairline).padding(.leading, 58)
            metricRow(symbol: "flame.fill", tint: Color(hex: 0xFF9F0A), title: L10n.string("health.energy"), value: energyLabel)
            Divider().overlay(Palette.hairline).padding(.leading, 58)
            metricRow(symbol: "location.fill", tint: Color(hex: 0x64D2FF), title: L10n.string("health.distance"), value: distanceLabel)
            if !health.today.workouts.isEmpty {
                Divider().overlay(Palette.hairline)
                ForEach(health.today.workouts) { workout in
                    HStack(spacing: 12) {
                        Image(systemName: workout.kind.symbol)
                            .foregroundStyle(Palette.volt)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.string(workout.kind.titleKey))
                                .staerkWrappingText()
                            Text(L10n.format("health.minutes", workout.durationMinutes))
                                .font(.footnote)
                                .foregroundStyle(Palette.muted)
                                .staerkWrappingText()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var habitsDoneToday: Int {
        HabitScoring.dayScore(
            habits: todaysHabits,
            entries: todayEntries,
            trained: trainedToday,
            dateKey: todayKey
        )
    }

    private func habitCard(_ habit: Habit) -> some View {
        let entry = todayEntries.first { $0.habitID == habit.id } ?? HabitEntry(habitID: habit.id, dateKey: todayKey)
        return HabitDayCard(
            habit: habit,
            isOn: HabitScoring.isComplete(habit: habit, entry: entry, trained: trainedToday),
            count: entry.countValue,
            onToggle: { toggle(habit, entry: entry) },
            onCount: { next in
                var updated = entry
                updated.countValue = next
                try? app.habits.upsert(updated)
            }
        )
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

    private func metricRow(symbol: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint)
                    .frame(width: 36, height: 36)
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.body)
            Spacer()
            Text(value)
                .font(Typeface.title(22))
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

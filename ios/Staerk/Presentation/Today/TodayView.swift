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
            if todaysHabits.isEmpty {
                Card(padding: 0) {
                    EmptyState(symbol: "sparkles", message: L10n.string("today.nohabits"))
                }
            } else {
                HStack(alignment: .top, spacing: Space.m) {
                    ForEach(Array(habitColumns.enumerated()), id: \.offset) { _, column in
                        VStack(spacing: Space.m) {
                            ForEach(column, id: \.id) { habit in
                                habitTile(habit)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    /// Greedy masonry: each habit goes to the shorter column, weighted by how tall its tile renders.
    private var habitColumns: [[Habit]] {
        var columns: [[Habit]] = [[], []]
        var heights: [Double] = [0, 0]
        for habit in todaysHabits {
            let weight: Double = habit.kind == .counter ? 1.45 : (habit.notes.isEmpty ? 1 : 1.25)
            let target = heights[0] <= heights[1] ? 0 : 1
            columns[target].append(habit)
            heights[target] += weight
        }
        return columns
    }

    @ViewBuilder
    private func habitTile(_ habit: Habit) -> some View {
        let entry = todayEntries.first { $0.habitID == habit.id } ?? HabitEntry(habitID: habit.id, dateKey: todayKey)
        let flourish = HabitFlourish(symbol: habit.symbol, kind: habit.kind)
        switch habit.kind {
        case .boolean, .workout:
            HabitCheckTile(
                title: habit.name,
                hint: habit.notes,
                tint: Color(hexString: habit.tintHex),
                symbol: habit.symbol,
                flourish: flourish,
                isOn: HabitScoring.isComplete(habit: habit, entry: entry, trained: trainedToday)
            ) {
                toggle(habit, entry: entry)
            }
        case .counter:
            HabitCounterTile(
                title: habit.name,
                tint: Color(hexString: habit.tintHex),
                symbol: habit.symbol,
                flourish: flourish,
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

// MARK: - Habit tiles

private let tileRadius = Radius.card - 4
private let glyphSize: CGFloat = 44
private let checkSize: CGFloat = 30

/// How a habit's icon celebrates, picked from its symbol so each habit reacts in character.
private enum HabitFlourish {
    case splash
    case wiggle
    case lift
    case jump
    case swing
    case stamp
    case bounce

    init(symbol: String, kind: HabitKind) {
        let s = symbol.lowercased()
        if s.contains("drop") || s.contains("cup") || s.contains("mug") || s.contains("waterbottle") {
            self = .splash
        } else if s.contains("pill") || s.contains("capsule") || s.contains("fork") || s.contains("leaf") {
            self = .wiggle
        } else if kind == .workout || s.contains("dumbbell") || s.contains("strength") {
            self = .lift
        } else if s.contains("golf") || s.contains("tennis") || s.contains("baseball") {
            self = .swing
        } else if s.contains("figure") || s.contains("bicycle") || s.contains("shoe") {
            self = .jump
        } else if s.contains("nosign") || s.contains("slash") || s.contains("xmark") {
            self = .stamp
        } else {
            self = .bounce
        }
    }

    var peakScale: Double {
        switch self {
        case .stamp: return 1.24
        case .lift, .jump: return 1.14
        default: return 1.1
        }
    }

    /// Vertical pull on burst particles: droplets fall, effort sparks rise.
    var drift: Double {
        switch self {
        case .splash: return 26
        case .lift, .jump: return -22
        default: return 0
        }
    }
}

private struct FlourishEffect: ViewModifier {
    var flourish: HabitFlourish
    var trigger: Int

    func body(content: Content) -> some View {
        switch flourish {
        case .splash: content.symbolEffect(.bounce.down.byLayer, value: trigger)
        case .wiggle: content.symbolEffect(.wiggle.byLayer, value: trigger)
        case .lift: content.symbolEffect(.bounce.up.byLayer, options: .repeat(.periodic(2)), value: trigger)
        case .jump: content.symbolEffect(.bounce.up.byLayer, value: trigger)
        case .swing: content.symbolEffect(.rotate.byLayer, value: trigger)
        case .stamp: content.symbolEffect(.bounce.down.wholeSymbol, value: trigger)
        case .bounce: content.symbolEffect(.bounce.byLayer, value: trigger)
        }
    }
}

private struct HabitGlyph: View {
    var symbol: String
    var tint: Color
    var onFill: Bool
    var flourish: HabitFlourish
    var trigger: Int

    var body: some View {
        let peak = flourish.peakScale
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(onFill ? tint.onTint.opacity(0.14) : tint.opacity(0.16))
            .frame(width: glyphSize, height: glyphSize)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(onFill ? tint.onTint : tint.legible)
                    .modifier(FlourishEffect(flourish: flourish, trigger: trigger))
            }
            .keyframeAnimator(initialValue: 1.0, trigger: trigger) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                SpringKeyframe(peak, duration: 0.14, spring: .snappy)
                SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
            }
            .accessibilityHidden(true)
    }
}

/// A ring of particles thrown out of the glyph when a habit is completed.
private struct Burst: View {
    var trigger: Int
    var color: Color
    var drift: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion {
            KeyframeAnimator(initialValue: 0.0, trigger: trigger) { t in
                ZStack {
                    ForEach(0..<10, id: \.self) { index in
                        let angle = Double(index) / 10 * 2 * .pi + 0.35
                        let reach = 30 + Double(index % 3) * 9
                        let dot: CGFloat = index.isMultiple(of: 2) ? 6 : 4
                        Circle()
                            .fill(color)
                            .frame(width: dot, height: dot)
                            .scaleEffect(1 - t * 0.5)
                            .offset(
                                x: cos(angle) * reach * t,
                                y: sin(angle) * reach * t + drift * t * t
                            )
                            .opacity(t == 0 ? 0 : 1 - t)
                    }
                }
            } keyframes: { _ in
                CubicKeyframe(1.0, duration: 0.65)
            }
            .frame(width: glyphSize, height: glyphSize)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// The tile's colour flood: a circle that grows out of `origin` to cover the whole tile.
private struct InkFill: View {
    var isOn: Bool
    var tint: Color
    var origin: (CGSize) -> CGPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let diameter = hypot(geo.size.width, geo.size.height) * 2.2
            Circle()
                .fill(tint)
                .frame(width: diameter, height: diameter)
                .scaleEffect(isOn || reduceMotion ? 1 : 0.001)
                .opacity(reduceMotion && !isOn ? 0 : 1)
                .position(origin(geo.size))
        }
        .background(Palette.surface)
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: isOn)
    }
}

private struct TileCheck: View {
    var isOn: Bool
    var tint: Color

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.inkTertiary, lineWidth: 2)
                .opacity(isOn ? 0 : 1)
            Circle()
                .fill(tint.onTint)
                .scaleEffect(isOn ? 1 : 0.2)
                .opacity(isOn ? 1 : 0)
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(tint)
                .scaleEffect(isOn ? 1 : 0.4)
                .opacity(isOn ? 1 : 0)
                .symbolEffect(.bounce, value: isOn)
        }
        .frame(width: checkSize, height: checkSize)
        .animation(Motion.bouncy.delay(isOn ? 0.08 : 0), value: isOn)
        .accessibilityHidden(true)
    }
}

private struct TileBorder: ViewModifier {
    var visible: Bool

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: tileRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1)
                    .opacity(visible ? 1 : 0)
            }
    }
}

private struct HabitCheckTile: View {
    var title: String
    var hint: String
    var tint: Color
    var symbol: String
    var flourish: HabitFlourish
    var isOn: Bool
    var action: () -> Void

    @State private var burst = 0

    var body: some View {
        Button {
            if isOn { Haptics.tap() } else { Haptics.success() }
            withAnimation(Motion.bouncy) {
                action()
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    HabitGlyph(symbol: symbol, tint: tint, onFill: isOn, flourish: flourish, trigger: burst)
                        .overlay { Burst(trigger: burst, color: tint.onTint.opacity(0.85), drift: flourish.drift) }
                    Spacer(minLength: Space.s)
                    TileCheck(isOn: isOn, tint: tint)
                }
                Spacer(minLength: Space.l)
                Text(title)
                    .font(Typeface.rowTitle)
                    .foregroundStyle(isOn ? tint.onTint : Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !hint.isEmpty {
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(isOn ? tint.onTint.opacity(0.72) : Palette.inkSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, Space.xxs)
                }
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            .background {
                InkFill(isOn: isOn, tint: tint) { size in
                    CGPoint(x: size.width - Space.l - checkSize / 2, y: Space.l + checkSize / 2)
                }
            }
            .modifier(TileBorder(visible: !isOn))
            .contentShape(RoundedRectangle(cornerRadius: tileRadius, style: .continuous))
        }
        .buttonStyle(PressableStyle(scale: 0.96))
        .onChange(of: isOn) { _, on in
            if on { burst += 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? String(localized: "a11y.done") : String(localized: "a11y.todo"))
    }
}

/// Counter habits fill up like a glass: the level rises with each tap and sloshes as it lands.
private struct HabitCounterTile: View {
    var title: String
    var tint: Color
    var symbol: String
    var flourish: HabitFlourish
    var value: Int
    var goal: Int
    var onChange: (Int) -> Void

    @State private var shownLevel = 0.0
    @State private var slosh = 0.0
    @State private var bump = 0
    @State private var burst = 0

    private var isComplete: Bool { value >= goal }
    private var level: Double { goal > 0 ? min(1, Double(value) / Double(goal)) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                HabitGlyph(symbol: symbol, tint: tint, onFill: isComplete, flourish: flourish, trigger: bump)
                    .overlay { Burst(trigger: burst, color: tint.onTint.opacity(0.85), drift: flourish.drift) }
                Spacer(minLength: Space.s)
                if value > 0 {
                    stepButton(symbol: "minus", size: checkSize, prominent: false) { decrement() }
                        .transition(.scale.combined(with: .opacity))
                }
            }
            Spacer(minLength: Space.xl)
            Text(title)
                .font(Typeface.rowTitle)
                .foregroundStyle(isComplete ? tint.onTint : Palette.ink)
                .lineLimit(2)
            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(value)")
                        .font(Typeface.display(34))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(value)))
                        .foregroundStyle(isComplete ? tint.onTint : Palette.ink)
                    Text(verbatim: "/\(goal)")
                        .font(Typeface.title(16))
                        .foregroundStyle(isComplete ? tint.onTint.opacity(0.7) : Palette.inkSecondary)
                }
                Spacer(minLength: Space.xs)
                stepButton(symbol: "plus", size: 40, prominent: true) { increment() }
            }
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
        .background {
            ZStack {
                Palette.surface
                LiquidShape(level: shownLevel, phase: slosh, amplitude: 5)
                    .fill(isComplete ? tint : tint.opacity(0.22))
            }
        }
        .modifier(TileBorder(visible: !isComplete))
        .contentShape(RoundedRectangle(cornerRadius: tileRadius, style: .continuous))
        .onTapGesture { increment() }
        .animation(Motion.snappy, value: value)
        .animation(Motion.bouncy, value: isComplete)
        .onAppear { shownLevel = level }
        .onChange(of: level) { _, next in
            withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) {
                shownLevel = next
                slosh += .pi * 2
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Text(verbatim: "\(value)/\(goal)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: if value > 0 { decrement() }
            @unknown default: break
            }
        }
    }

    private func increment() {
        Haptics.tap()
        onChange(value + 1)
        bump += 1
        if value + 1 == goal {
            Haptics.success()
            burst += 1
        }
    }

    private func decrement() {
        Haptics.tap()
        onChange(max(0, value - 1))
    }

    private func stepButton(symbol: String, size: CGFloat, prominent: Bool, action: @escaping () -> Void) -> some View {
        let fill: Color = prominent
            ? (isComplete ? tint.onTint : tint)
            : (isComplete ? tint.onTint.opacity(0.16) : Palette.surfaceInsetStrong)
        let ink: Color = prominent
            ? (isComplete ? tint : tint.onTint)
            : (isComplete ? tint.onTint : Palette.inkSecondary)
        return Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .heavy))
                .foregroundStyle(ink)
                .frame(width: size, height: size)
                .background(fill, in: Circle())
                .frame(width: max(size, 44), height: max(size, 44))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle(scale: 0.86))
    }
}

/// Liquid with a gentle wave on top; the wave flattens out when empty or full.
private struct LiquidShape: Shape {
    var level: Double
    var phase: Double
    var amplitude: CGFloat

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(level, phase) }
        set {
            level = newValue.first
            phase = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(1, max(0, level))
        let surface = rect.maxY - rect.height * clamped
        let amp = amplitude * min(1, min(clamped, 1 - clamped) * 8)
        let steps = 28
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let x = rect.minX + rect.width * progress
            let y = surface + sin(progress * 2 * .pi * 1.3 + phase) * amp
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

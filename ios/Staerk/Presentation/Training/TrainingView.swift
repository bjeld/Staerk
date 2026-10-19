import SwiftData
import SwiftUI

struct TrainingView: View {
    @Query private var programRows: [ProgramRecord]
    @Query(sort: \WorkoutRecord.sortOrder) private var workoutRows: [WorkoutRecord]
    @Query(filter: #Predicate<ExerciseRecord> { !$0.archived }, sort: \ExerciseRecord.sortOrder)
    private var exerciseRows: [ExerciseRecord]
    @Query(sort: \SessionRecord.dateKey, order: .reverse) private var sessionRows: [SessionRecord]
    @Query private var scheduleRows: [ScheduleRecord]

    private var program: TrainingProgram? { programRows.first { $0.isActive }?.asDomain() ?? programRows.first?.asDomain() }
    private var workouts: [WorkoutPlan] {
        guard let program else { return [] }
        return workoutRows.filter { $0.programID == program.id }.map { $0.asDomain() }
    }
    private var sessions: [SessionLog] { sessionRows.map { $0.asDomain() } }
    private var schedule: WeeklySchedule { scheduleRows.first?.asDomain() ?? WeeklySchedule() }
    private var picked: WorkoutPlan? {
        ScheduleResolver.pickWorkout(schedule: schedule, workouts: workouts, sessions: sessions)
    }
    private var todayDone: SessionLog? {
        sessions.first { $0.dateKey == Dates.key() && $0.completed }
    }
    private var dayStatus: DayTrainingStatus {
        ScheduleResolver.status(on: Date(), schedule: schedule, workouts: workouts)
    }
    private var showsCircuitProgress: Bool {
        workouts.contains(where: \.isCircuit) || sessions.contains(where: \.isCircuit)
    }
    private var hasCompletedSessions: Bool {
        sessions.contains(where: \.completed)
    }
    private var circuitSummary: CircuitProgress.Summary {
        CircuitProgress.summary(
            sessions: sessions,
            schedule: schedule,
            today: Dates.key(),
            weekKeys: Dates.weekKeys()
        )
    }

    var body: some View {
        Screen {
            ScreenHeader(
                title: L10n.string("training.title"),
                subtitle: program?.name ?? L10n.string("training.empty.program")
            ) {
                NavigationLink {
                    ProgramEditorView()
                } label: {
                    CircleIcon(symbol: "slider.horizontal.3")
                }
                .buttonStyle(PressableStyle(scale: 0.92))
                .accessibilityLabel(L10n.string("training.edit.program"))
            }

            if workouts.isEmpty {
                emptyProgramCard
            } else {
                nextCard
            }

            if showsCircuitProgress {
                CircuitProgressCard(summary: circuitSummary)
            }

            ForEach(workouts) { workout in
                if workout.isCircuit {
                    circuitList(workout)
                } else {
                    workoutList(workout)
                }
            }

            if !workouts.isEmpty || hasCompletedSessions {
                history
            }
        }
        .navigationTitle(L10n.string("training.title"))
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Empty / next session

    private var emptyProgramCard: some View {
        Card(padding: Space.xl) {
            Eyebrow(text: L10n.string("training.empty.eyebrow"), color: Palette.accentInk)
            Text(L10n.string("training.empty.title"))
                .font(Typeface.display(32))
                .foregroundStyle(Palette.ink)
                .staerkWrappingText()
                .padding(.top, Space.xs)
            Text(L10n.string("training.empty.body"))
                .font(.subheadline)
                .foregroundStyle(Palette.inkSecondary)
                .staerkWrappingText()
                .padding(.top, Space.s)
            NavigationLink {
                ProgramEditorView()
            } label: {
                ButtonLabel(title: L10n.string("training.empty.cta"), symbol: "plus")
            }
            .buttonStyle(.staerkPrimary)
            .padding(.top, Space.l)
        }
    }

    private var nextWorkout: WorkoutPlan? {
        if let todayDone { return workouts.first { $0.id == todayDone.workoutID } }
        return picked
    }

    private var nextCard: some View {
        Card(padding: Space.xl) {
            HStack {
                Eyebrow(text: nextEyebrow, color: Palette.accentInk)
                Spacer()
                if todayDone != nil {
                    Pill(text: L10n.string("session.completed"))
                }
            }

            Text(todayDone?.workoutName ?? picked?.name ?? L10n.string("training.unscheduled"))
                .font(Typeface.display(38))
                .foregroundStyle(Palette.ink)
                .staerkWrappingText()
                .padding(.top, Space.xs)

            if let nextWorkout, !nextWorkout.isCircuit {
                Text(summary(for: nextWorkout))
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSecondary)
                    .staerkWrappingText()
                    .padding(.top, Space.xxs)
            }

            NavigationLink {
                ScheduleEditorView()
            } label: {
                scheduleStrip
            }
            .buttonStyle(.pressable)
            .padding(.top, Space.xl)

            Text(nextBody)
                .font(.footnote)
                .foregroundStyle(Palette.inkSecondary)
                .staerkWrappingText()
                .padding(.top, Space.l)

            NavigationLink {
                SessionView()
            } label: {
                ButtonLabel(
                    title: startTitle,
                    symbol: todayDone == nil ? "play.fill" : "plus"
                )
            }
            .buttonStyle(todayDone == nil ? .staerkPrimary : .staerkSecondary)
            .padding(.top, Space.l)
        }
    }

    private var nextEyebrow: String {
        switch dayStatus {
        case .training:
            return L10n.string("training.next.today")
        case .rest:
            return L10n.string("training.next.rest")
        case .unconfigured:
            return L10n.string("training.next.today")
        }
    }

    private var nextBody: String {
        switch dayStatus {
        case .rest:
            return L10n.string("training.rest.body")
        case .training:
            if picked?.isCircuit == true {
                return L10n.string("training.next.body.circuit")
            }
            return L10n.string("training.next.body")
        case .unconfigured:
            return L10n.string("training.unscheduled.body")
        }
    }

    private var startTitle: String {
        if todayDone != nil {
            return L10n.string("training.new")
        }
        if picked?.isCircuit == true {
            return L10n.string("training.start.circuit")
        }
        return L10n.string("training.start")
    }

    private var scheduleStrip: some View {
        let week = Dates.weekKeys()
        let today = Dates.key()
        let trained = Set(sessions.filter(\.completed).map(\.dateKey))
        return VStack(alignment: .leading, spacing: Space.m) {
            HStack {
                Text(L10n.string("training.schedule"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.inkSecondary)
                Spacer()
                Chevron()
            }
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { index, key in
                    let scheduled = schedule.workoutIDs[index] != nil
                    let done = trained.contains(key)
                    let isToday = key == today
                    VStack(spacing: Space.s) {
                        Text(String(L10n.string(WeekdayLabel.shortKeys[index]).prefix(1)).uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(isToday ? Palette.accentInk : Palette.inkTertiary)
                        ZStack {
                            Circle()
                                .fill(done ? Palette.accent : (scheduled ? Palette.accentSoft : Palette.surfaceInset))
                            if done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(Palette.onAccent)
                            } else if scheduled {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Palette.accentInk)
                            }
                        }
                        .frame(width: 30, height: 30)
                        .overlay {
                            if isToday {
                                Circle().strokeBorder(Palette.ink, lineWidth: 1.5).padding(-4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Space.m + 2)
        .insetSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.string("training.schedule"))
        .accessibilityAddTraits(.isButton)
    }

    private func summary(for workout: WorkoutPlan) -> String {
        let items = exerciseRows.filter { $0.workoutID == workout.id }.map { $0.asDomain() }
        let muscles = Array(NSOrderedSet(array: items.map { $0.muscleGroup.localizedName })) as? [String] ?? []
        return ([L10n.format("training.exercise.count", items.count)] + muscles.prefix(3)).joined(separator: " · ")
    }

    // MARK: Workouts

    private func circuitList(_ workout: WorkoutPlan) -> some View {
        let active = picked?.id == workout.id && todayDone == nil
        return TitledSection(title: active ? L10n.format("training.workout.today", workout.name) : workout.name) {
            if active {
                Pill(text: L10n.string("tab.today"))
            }
        } content: {
            Card {
                VStack(alignment: .leading, spacing: Space.s) {
                    if !workout.trimmedLocation.isEmpty {
                        Label(workout.trimmedLocation, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkSecondary)
                            .staerkWrappingText()
                    }
                    Pill(text: L10n.string("workout.kind.circuit"), tint: Palette.accent, filled: false)
                    if workout.stations.isEmpty {
                        Text(L10n.string("training.nostations"))
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkSecondary)
                            .staerkWrappingText()
                    } else {
                        ForEach(Array(workout.stations.enumerated()), id: \.element.id) { index, station in
                            Text("\(index + 1). \(station.name)")
                                .font(.body)
                                .foregroundStyle(Palette.ink)
                                .staerkWrappingText()
                        }
                    }
                }
            }
        }
    }

    private func workoutList(_ workout: WorkoutPlan) -> some View {
        let items = exerciseRows.filter { $0.workoutID == workout.id }.map { $0.asDomain() }
        let active = picked?.id == workout.id && todayDone == nil
        return TitledSection(title: workout.name) {
            if active {
                Pill(text: L10n.string("tab.today"))
            }
        } content: {
            Card(padding: 0) {
                if items.isEmpty {
                    EmptyState(symbol: "dumbbell", message: L10n.string("training.noexercises"))
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, exercise in
                        NavigationLink {
                            ExerciseHistoryView(exerciseID: exercise.id)
                        } label: {
                            ListRow(title: exercise.name, detail: exercise.muscleGroup.localizedName) {
                                Text("\(index + 1)")
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Palette.inkSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(Palette.surfaceInset, in: Circle())
                            } trailing: {
                                Text(spec(exercise))
                                    .font(.subheadline.weight(.medium).monospacedDigit())
                                    .foregroundStyle(Palette.inkSecondary)
                                Chevron()
                            }
                        }
                        .buttonStyle(.pressable)
                        if index < items.count - 1 {
                            RowDivider(inset: 60)
                        }
                    }
                }
            }
        }
    }

    // MARK: History

    private var history: some View {
        let recent = Array(sessions.filter(\.completed).prefix(8))
        return TitledSection(title: L10n.string("training.history")) {
            Card(padding: 0) {
                if recent.isEmpty {
                    EmptyState(symbol: "clock.arrow.circlepath", message: L10n.string("training.history.empty"))
                } else {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, session in
                        NavigationLink {
                            SessionDetailView(sessionID: session.id)
                        } label: {
                            ListRow(
                                title: session.workoutName,
                                detail: historySubtitle(session)
                            ) {
                                DateBlock(dateKey: session.dateKey)
                            } trailing: {
                                Chevron()
                            }
                        }
                        .buttonStyle(.pressable)
                        if index < recent.count - 1 {
                            RowDivider(inset: 72)
                        }
                    }
                }
            }
        }
    }

    private func weekday(_ key: String) -> String {
        let raw = Dates.parse(key).formatted(.dateTime.weekday(.wide))
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    private func historySubtitle(_ session: SessionLog) -> String {
        if session.isCircuit {
            var parts = [weekday(session.dateKey)]
            if let minutes = session.resolvedDurationMinutes {
                parts.append(L10n.format("circuit.minutes.short", minutes))
            }
            if let effort = session.effort {
                parts.append(L10n.format("circuit.effort.short", effort))
            }
            return parts.joined(separator: " · ")
        }
        return L10n.format("training.history.row", weekday(session.dateKey), session.doneSetCount)
    }

    private func spec(_ exercise: ExerciseDefinition) -> String {
        if exercise.logType == .seconds {
            return "\(exercise.defaultRepsMin)–\(exercise.defaultRepsMax) s"
        }
        return "\(exercise.defaultSets) × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)"
    }
}

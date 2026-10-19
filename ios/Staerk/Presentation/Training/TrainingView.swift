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
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(
                    title: L10n.string("training.title"),
                    subtitle: program?.name ?? L10n.string("training.empty.program")
                )

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

                NavigationLink {
                    ProgramEditorView()
                } label: {
                    Text(workouts.isEmpty ? L10n.string("training.empty.cta") : L10n.string("training.edit.program"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(workouts.isEmpty ? Palette.voltForeground : Color.primary)
                        .staerkWrappingText()
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                        .background(
                            workouts.isEmpty ? Palette.volt : Palette.fill,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .staerkKeyboard()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var emptyProgramCard: some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("training.empty.eyebrow"))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Palette.volt)
                    .textCase(.uppercase)
                Text(L10n.string("training.empty.title"))
                    .font(Typeface.display(32))
                    .staerkWrappingText()
                Text(L10n.string("training.empty.body"))
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .staerkWrappingText()
            }
            .padding(16)
        }
    }

    private var nextCard: some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(nextEyebrow)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Palette.volt)
                    .textCase(.uppercase)
                Text(todayDone?.workoutName ?? picked?.name ?? L10n.string("training.unscheduled"))
                    .font(Typeface.display(32))
                    .staerkWrappingText()
                Text(nextBody)
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .staerkWrappingText()

                HStack(spacing: 8) {
                    NavigationLink {
                        SessionView()
                    } label: {
                        Text(startTitle)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Palette.voltForeground)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 56)
                            .background(Palette.volt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ScheduleEditorView()
                    } label: {
                        Text(L10n.string("training.schedule"))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 56)
                            .background(Palette.fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            .padding(16)
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

    private func circuitList(_ workout: WorkoutPlan) -> some View {
        let active = picked?.id == workout.id && todayDone == nil
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: active ? L10n.format("training.workout.today", workout.name) : workout.name)
            GroupedCard {
                VStack(alignment: .leading, spacing: 10) {
                    if !workout.trimmedLocation.isEmpty {
                        Label(workout.trimmedLocation, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                    }
                    Text(L10n.string("workout.kind.circuit"))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Palette.volt)
                    if workout.stations.isEmpty {
                        Text(L10n.string("training.nostations"))
                            .foregroundStyle(Palette.muted)
                    } else {
                        ForEach(Array(workout.stations.enumerated()), id: \.element.id) { index, station in
                            Text("\(index + 1). \(station.name)")
                                .font(.body)
                                .staerkWrappingText()
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func workoutList(_ workout: WorkoutPlan) -> some View {
        let items = exerciseRows.filter { $0.workoutID == workout.id }.map { $0.asDomain() }
        let active = picked?.id == workout.id && todayDone == nil
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: active ? L10n.format("training.workout.today", workout.name) : workout.name)
            GroupedCard {
                if items.isEmpty {
                    Text(L10n.string("training.noexercises"))
                        .foregroundStyle(Palette.muted)
                        .padding(16)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, exercise in
                        NavigationLink {
                            ExerciseHistoryView(exerciseID: exercise.id)
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .foregroundStyle(.primary)
                                        .staerkWrappingText()
                                    Text(subtitle(exercise))
                                        .font(.footnote)
                                        .foregroundStyle(Palette.muted)
                                        .staerkWrappingText()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.muted)
                                    .padding(.top, 4)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        if index < items.count - 1 {
                            Divider().overlay(Palette.hairline).padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private var history: some View {
        let recent = Array(sessions.filter(\.completed).prefix(8))
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: L10n.string("training.history"))
            GroupedCard {
                if recent.isEmpty {
                    Text(L10n.string("training.history.empty"))
                        .foregroundStyle(Palette.muted)
                        .padding(16)
                } else {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, session in
                        NavigationLink {
                            SessionDetailView(sessionID: session.id)
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.workoutName)
                                        .foregroundStyle(.primary)
                                        .staerkWrappingText()
                                    Text(historySubtitle(session))
                                        .font(.footnote)
                                        .foregroundStyle(Palette.muted)
                                        .staerkWrappingText()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.muted)
                                    .padding(.top, 4)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        if index < recent.count - 1 {
                            Divider().overlay(Palette.hairline).padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private func historySubtitle(_ session: SessionLog) -> String {
        if session.isCircuit {
            var parts = [Dates.prettyShort(key: session.dateKey)]
            if let minutes = session.resolvedDurationMinutes {
                parts.append(L10n.format("circuit.minutes.short", minutes))
            }
            if let effort = session.effort {
                parts.append(L10n.format("circuit.effort.short", effort))
            }
            return parts.joined(separator: " · ")
        }
        return L10n.format("training.history.row", Dates.prettyShort(key: session.dateKey), session.doneSetCount)
    }

    private func subtitle(_ exercise: ExerciseDefinition) -> String {
        if exercise.logType == .seconds {
            return "\(exercise.muscleGroup.localizedName) · \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax) s"
        }
        return "\(exercise.muscleGroup.localizedName) · \(exercise.defaultSets) × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)"
    }
}

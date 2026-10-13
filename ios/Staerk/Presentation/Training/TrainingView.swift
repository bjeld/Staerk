import SwiftData
import SwiftUI

struct TrainingView: View {
    @Query private var programRows: [ProgramRecord]
    @Query(sort: \WorkoutRecord.sortOrder) private var workoutRows: [WorkoutRecord]
    @Query(filter: #Predicate<ExerciseRecord> { !$0.archived }, sort: \ExerciseRecord.sortOrder)
    private var exerciseRows: [ExerciseRecord]
    @Query(sort: \SessionRecord.dateKey, order: .reverse) private var sessionRows: [SessionRecord]
    @Query private var scheduleRows: [ScheduleRecord]
    @Query private var settingsRows: [SettingsRecord]

    private var settings: UserSettings { settingsRows.first?.asDomain() ?? UserSettings() }
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
    private var isTrainingDay: Bool { ScheduleResolver.isTrainingDay(date: Date(), schedule: schedule) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(
                    title: L10n.string("training.title"),
                    subtitle: program?.name ?? L10n.string("training.empty.program")
                )

                nextCard

                ForEach(workouts) { workout in
                    workoutList(workout)
                }

                history

                NavigationLink {
                    ProgramEditorView()
                } label: {
                    Text(L10n.string("training.edit.program"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                        .background(Palette.fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private var nextCard: some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(isTrainingDay ? L10n.string("training.next.today") : L10n.string("training.next.rest"))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Palette.volt)
                    .textCase(.uppercase)
                Text(todayDone?.workoutName ?? picked?.name ?? L10n.string("training.unscheduled"))
                    .font(Typeface.display(32))
                Text(isTrainingDay ? L10n.string("training.next.body") : L10n.string("training.rest.body"))
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)

                HStack(spacing: 8) {
                    NavigationLink {
                        SessionView()
                    } label: {
                        Text(todayDone == nil ? L10n.string("training.start") : L10n.string("training.new"))
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
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name).foregroundStyle(.primary)
                                    Text(subtitle(exercise))
                                        .font(.footnote)
                                        .foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.muted)
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
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.workoutName).foregroundStyle(.primary)
                                    Text(L10n.format("training.history.row", Dates.prettyShort(key: session.dateKey), session.doneSetCount))
                                        .font(.footnote)
                                        .foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.muted)
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

    private func subtitle(_ exercise: ExerciseDefinition) -> String {
        if exercise.logType == .seconds {
            return "\(exercise.muscleGroup.localizedName) · \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax) s"
        }
        return "\(exercise.muscleGroup.localizedName) · \(exercise.defaultSets) × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)"
    }
}

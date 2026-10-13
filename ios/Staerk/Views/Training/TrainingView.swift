import SwiftData
import SwiftUI

struct TrainingView: View {
    @Query(filter: #Predicate<Exercise> { !$0.archived }, sort: \Exercise.order) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.dateKey, order: .reverse) private var sessions: [WorkoutSession]

    private var letter: WorkoutLetter { Schedule.pickWorkoutLetter(sessions: sessions) }
    private var kind: DayKind { Schedule.dayKind() }
    private var todayDone: WorkoutSession? {
        sessions.first(where: { $0.dateKey == Dates.key() && $0.completed })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(
                    title: "Træning",
                    subtitle: "Fuldkropsstyrke 3× om ugen, ~45 min. Man/ons/fre tidligt på jobbet."
                )

                nextCard
                programList(letter: .A)
                programList(letter: .B)
                history
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var nextCard: some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(kind == .gym ? "Næste pas" : "Næste gym-dag")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.accent)
                Text("Program \((todayDone?.workout ?? letter).rawValue)")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.6)
                Text(
                    kind == .gym
                        ? "Log sæt, mens pulsen stadig er oppe — så husker du tallene."
                        : "I dag er restitution. Programmet venter til næste mandag, onsdag eller fredag."
                )
                .font(.system(size: 15))
                .foregroundStyle(Palette.muted)

                HStack(spacing: 8) {
                    NavigationLink {
                        SessionView()
                    } label: {
                        Text(todayDone == nil ? "Start pas" : "Nyt pas")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Palette.accentForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ProgramView()
                    } label: {
                        Text("Rediger")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
    }

    private func programList(letter: WorkoutLetter) -> some View {
        let items = exercises.filter { $0.workout == letter }
        let active = self.letter == letter && todayDone == nil
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: active ? "Program \(letter.rawValue) · i dag" : "Program \(letter.rawValue)")
            GroupedCard {
                ForEach(items, id: \.id) { exercise in
                    NavigationLink {
                        ExerciseHistoryView(exerciseID: exercise.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.system(size: 17))
                                    .foregroundStyle(.primary)
                                Text(subtitle(for: exercise))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    if exercise.id != items.last?.id {
                        Divider().overlay(Palette.hairline).padding(.leading, 16)
                    }
                }
            }
        }
    }

    private var history: some View {
        let recent = sessions.filter(\.completed).prefix(8)
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Historik")
            GroupedCard {
                if recent.isEmpty {
                    Text("Ingen pas logget endnu. Første uge er den sværeste — så bliver det vane.")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                        .padding(16)
                } else {
                    ForEach(Array(recent), id: \.id) { session in
                        NavigationLink {
                            SessionDetailView(sessionID: session.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Program \(session.workout.rawValue)")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.primary)
                                    Text("\(Dates.prettyShort(key: session.dateKey)) · \(session.doneSetCount) sæt")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Palette.muted)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        if session.id != recent.last?.id {
                            Divider().overlay(Palette.hairline).padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private func subtitle(for exercise: Exercise) -> String {
        if exercise.logType == .seconds {
            return "\(exercise.muscleGroup.label) · \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax) sek"
        }
        return "\(exercise.muscleGroup.label) · \(exercise.defaultSets) × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)"
    }
}

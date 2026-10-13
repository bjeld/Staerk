import Charts
import SwiftData
import SwiftUI

struct HabitsView: View {
    @Query private var settingsRows: [AppSettings]
    @Query(sort: \DayLog.dateKey) private var days: [DayLog]
    @Query private var sessions: [WorkoutSession]
    @Query private var exercises: [Exercise]
    @State private var cursor = Date()

    private var settings: AppSettings { settingsRows.first ?? AppSettings.makeDefault() }
    private var waterGoal: Int { settings.waterGoal }
    private var today: String { Dates.key() }
    private var week: [String] { Dates.weekKeys() }
    private var trainedDates: Set<String> {
        Set(sessions.filter(\.completed).map(\.dateKey))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(title: "Vaner", subtitle: "En uge ad gangen. Konsistens slår hero-pas.")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    streakCard(
                        title: "Kreatin",
                        value: HabitLogic.streak(days: days, today: today, pred: \.creatine),
                        unit: "dage",
                        color: Palette.ringMove
                    )
                    streakCard(
                        title: "Vandmål",
                        value: HabitLogic.streak(days: days, today: today) { $0.waterGlasses >= waterGoal },
                        unit: "dage",
                        color: Palette.ringExercise
                    )
                    streakCard(
                        title: "Alkoholfri",
                        value: HabitLogic.streak(days: days, today: today, pred: \.alcoholFree),
                        unit: "dage",
                        color: Palette.ringStand
                    )
                    streakCard(
                        title: "Gym-række",
                        value: HabitLogic.trainingStreak(sessions: sessions, today: today),
                        unit: "pas",
                        color: Palette.orange
                    )
                }

                weekTable
                muscleVolume
                calendar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func streakCard(title: String, value: Int, unit: String, color: Color) -> some View {
        GroupedCard {
            VStack(spacing: 8) {
                ProgressRingView(
                    value: Double(min(value, 14)),
                    maxValue: 14,
                    color: color,
                    label: "\(value)",
                    sub: unit
                )
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(12)
        }
    }

    private var weekTable: some View {
        let score = HabitLogic.weekScore(days: days, week: week, waterGoal: waterGoal)
        let byDate = Dictionary(uniqueKeysWithValues: days.map { ($0.dateKey, $0) })
        return GroupedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Denne uge")
                        .font(.system(size: 20, weight: .semibold))
                    Spacer()
                    Text("\(score)/21 vaner")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                }
                HStack {
                    Text("Dag").frame(maxWidth: .infinity, alignment: .leading)
                    Text("K").frame(width: 28)
                    Text("V").frame(width: 28)
                    Text("A").frame(width: 28)
                    Text("T").frame(width: 28)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.muted)

                ForEach(Array(week.enumerated()), id: \.offset) { index, key in
                    let d = byDate[key]
                    let isToday = key == today
                    HStack {
                        Text(isToday ? "\(WeekdayLabel.short[index]) · i dag" : WeekdayLabel.short[index])
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fontWeight(isToday ? .semibold : .regular)
                        mark(d?.creatine == true)
                        mark((d?.waterGlasses ?? 0) >= waterGoal && d != nil)
                        mark(d?.alcoholFree == true)
                        mark(trainedDates.contains(key))
                    }
                    .font(.system(size: 15))
                }

                Text("K = kreatin · V = vandmål · A = alkoholfri · T = træning")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
            }
            .padding(16)
        }
    }

    private var muscleVolume: some View {
        let muscleMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0.muscleGroup) })
        let volume = Progression.weeklySetVolume(
            sessions: sessions,
            weekStart: week.first ?? today,
            weekEnd: week.last ?? today,
            muscleOf: { muscleMap[$0] }
        )
        let data = MuscleGroup.allCases.map { MuscleVolume(id: $0.rawValue, name: $0.label, sets: volume[$0] ?? 0) }
        let empty = data.allSatisfy { $0.sets == 0 }

        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Ugens sæt pr. muskel")
            GroupedCard {
                if empty {
                    Text("Ingen sæt denne uge endnu.")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                        .padding(16)
                } else {
                    Chart(data) { item in
                        BarMark(
                            x: .value("Muskel", item.name),
                            y: .value("Sæt", item.sets)
                        )
                        .foregroundStyle(Palette.accent)
                    }
                    .frame(height: 180)
                    .padding(16)
                }
            }
        }
    }

    private var calendar: some View {
        let cells = Dates.monthGrid(cursor)
        let byDate = Dictionary(uniqueKeysWithValues: days.map { ($0.dateKey, $0) })
        return GroupedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button {
                        cursor = Dates.calendar.date(byAdding: .month, value: -1, to: cursor) ?? cursor
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(Dates.monthTitle(cursor))
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button {
                        cursor = Dates.calendar.date(byAdding: .month, value: 1, to: cursor) ?? cursor
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundStyle(.primary)

                HStack {
                    ForEach(WeekdayLabel.short, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.muted)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, key in
                        if let key {
                            let score = HabitLogic.dayScore(
                                day: byDate[key],
                                trained: trainedDates.contains(key),
                                waterGoal: waterGoal
                            )
                            Text(dayNumber(key))
                                .font(.system(size: 12, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(cellColor(score: score), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    if key == today {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Palette.accent, lineWidth: 2)
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
        let day = Int(key.suffix(2)) ?? 0
        return String(day)
    }

    private func mark(_ ok: Bool) -> some View {
        Text(ok ? "●" : "○")
            .frame(width: 28)
            .foregroundStyle(ok ? Palette.accent : Palette.muted)
    }

    private func cellColor(score: Int) -> Color {
        if score == 0 { return Palette.fill }
        return Palette.accent.opacity(0.18 + Double(score) * 0.16)
    }
}

private struct MuscleVolume: Identifiable {
    var id: String
    var name: String
    var sets: Int
}

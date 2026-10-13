import Foundation

enum StreakCalculator {
    /// Consecutive applicable days ending today. An incomplete today is skipped so
    /// the streak stays intact until the day is over.
    static func streak(
        today: String,
        applies: (String) -> Bool,
        isComplete: (String) -> Bool
    ) -> Int {
        var count = 0
        var cursor = Dates.parse(today)
        for _ in 0..<400 {
            let key = Dates.key(cursor)
            if !applies(key) {
                cursor = Dates.adding(days: -1, to: cursor)
                continue
            }
            if key == today && !isComplete(key) {
                cursor = Dates.adding(days: -1, to: cursor)
                continue
            }
            if isComplete(key) {
                count += 1
                cursor = Dates.adding(days: -1, to: cursor)
            } else {
                break
            }
        }
        return count
    }

    static func habitStreak(
        habit: Habit,
        entries: [HabitEntry],
        sessions: [SessionLog] = [],
        today: String
    ) -> Int {
        let map = Dictionary(uniqueKeysWithValues: entries.filter { $0.habitID == habit.id }.map { ($0.dateKey, $0) })
        let trained = Set(sessions.filter(\.completed).map(\.dateKey))
        return streak(
            today: today,
            applies: { habit.applies(onKey: $0) },
            isComplete: { key in
                HabitScoring.isComplete(habit: habit, entry: map[key], trained: trained.contains(key))
            }
        )
    }
}

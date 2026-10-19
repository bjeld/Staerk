import Foundation

enum HabitScoring {
    /// Workout habits stay on the Habits tab so they can be edited, but they
    /// should not dangle on Today after the last program/workout is deleted.
    static func excludingDanglingWorkoutHabits(_ habits: [Habit], hasWorkouts: Bool) -> [Habit] {
        guard !hasWorkouts else { return habits }
        return habits.filter { $0.kind != .workout }
    }

    static func isComplete(habit: Habit, entry: HabitEntry?, trained: Bool) -> Bool {
        switch habit.kind {
        case .boolean:
            return entry?.boolValue == true
        case .counter:
            return (entry?.countValue ?? 0) >= habit.goal
        case .workout:
            return entry?.boolValue == true || trained
        }
    }

    static func progress(habit: Habit, entry: HabitEntry?, trained: Bool) -> Double {
        switch habit.kind {
        case .boolean, .workout:
            return isComplete(habit: habit, entry: entry, trained: trained) ? 1 : 0
        case .counter:
            guard habit.goal > 0 else { return 0 }
            return min(1, Double(entry?.countValue ?? 0) / Double(habit.goal))
        }
    }

    static func dayRatio(
        habits: [Habit],
        entries: [HabitEntry],
        trained: Bool,
        dateKey: String
    ) -> Double {
        let applicable = habits.filter { !$0.archived && $0.applies(onKey: dateKey) }
        guard !applicable.isEmpty else { return trained ? 1 : 0 }
        let map = Dictionary(uniqueKeysWithValues: entries.map { ($0.habitID, $0) })
        let done = applicable.filter { habit in
            isComplete(habit: habit, entry: map[habit.id], trained: trained)
        }.count
        return Double(done) / Double(applicable.count)
    }

    static func dayScore(
        habits: [Habit],
        entries: [HabitEntry],
        trained: Bool,
        dateKey: String
    ) -> Int {
        let applicable = habits.filter { !$0.archived && $0.applies(onKey: dateKey) }
        let map = Dictionary(uniqueKeysWithValues: entries.map { ($0.habitID, $0) })
        return applicable.filter { habit in
            isComplete(habit: habit, entry: map[habit.id], trained: trained)
        }.count
    }

    static func weekCompletedCount(
        habits: [Habit],
        entries: [HabitEntry],
        trainedDates: Set<String>,
        week: [String]
    ) -> (done: Int, total: Int) {
        let entryMap = Dictionary(grouping: entries, by: \.dateKey)
        var done = 0
        var total = 0
        for key in week {
            let applicable = habits.filter { !$0.archived && $0.applies(onKey: key) }
            total += applicable.count
            let dayEntries = Dictionary(uniqueKeysWithValues: (entryMap[key] ?? []).map { ($0.habitID, $0) })
            let trained = trainedDates.contains(key)
            done += applicable.filter { isComplete(habit: $0, entry: dayEntries[$0.id], trained: trained) }.count
        }
        return (done, total)
    }

    static func toggled(_ entry: HabitEntry, habit: Habit) -> HabitEntry {
        var next = entry
        switch habit.kind {
        case .boolean, .workout:
            next.boolValue.toggle()
        case .counter:
            break
        }
        return next
    }

    static func increment(_ entry: HabitEntry, by delta: Int, minimum: Int = 0) -> HabitEntry {
        var next = entry
        next.countValue = max(minimum, next.countValue + delta)
        return next
    }
}

import Foundation

enum HabitLogic {
    static func streak(days: [DayLog], today: String, pred: (DayLog) -> Bool) -> Int {
        let map = Dictionary(uniqueKeysWithValues: days.map { ($0.dateKey, $0) })
        var count = 0
        var cursor = Dates.parse(today)
        for _ in 0..<400 {
            let key = Dates.key(cursor)
            guard let row = map[key], pred(row) else { break }
            count += 1
            cursor = Dates.adding(days: -1, to: cursor)
        }
        return count
    }

    static func trainingStreak(sessions: [WorkoutSession], today: String) -> Int {
        let dates = Set(sessions.filter(\.completed).map(\.dateKey))
        var trainingDays: [String] = []
        var cursor = Dates.parse(today)
        for _ in 0..<180 {
            let weekday = Dates.calendar.component(.weekday, from: cursor)
            // Monday / Wednesday / Friday
            if weekday == 2 || weekday == 4 || weekday == 6 {
                trainingDays.append(Dates.key(cursor))
            }
            cursor = Dates.adding(days: -1, to: cursor)
        }

        var count = 0
        for key in trainingDays {
            if key == today && !dates.contains(key) {
                continue
            }
            if !dates.contains(key) {
                break
            }
            count += 1
        }
        return count
    }

    static func weekScore(days: [DayLog], week: [String], waterGoal: Int) -> Int {
        let map = Dictionary(uniqueKeysWithValues: days.map { ($0.dateKey, $0) })
        return week.reduce(0) { total, key in
            guard let day = map[key] else { return total }
            return total
                + (day.creatine ? 1 : 0)
                + (day.waterGlasses >= waterGoal ? 1 : 0)
                + (day.alcoholFree ? 1 : 0)
        }
    }

    static func dayScore(day: DayLog?, trained: Bool, waterGoal: Int) -> Int {
        guard let day else { return trained ? 1 : 0 }
        return (day.creatine ? 1 : 0)
            + (day.waterGlasses >= waterGoal ? 1 : 0)
            + (day.alcoholFree ? 1 : 0)
            + (trained ? 1 : 0)
    }
}

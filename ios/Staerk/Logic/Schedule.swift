import Foundation

enum Schedule {
    /// Monday-first: 0 = mandag … 6 = søndag.
    static func weekdayIndex(_ date: Date = Date()) -> Int {
        (Dates.calendar.component(.weekday, from: date) + 5) % 7
    }

    static func dayKind(_ date: Date = Date()) -> DayKind {
        switch weekdayIndex(date) {
        case 0, 2, 4: return .gym
        case 1, 3: return .home
        default: return .weekend
        }
    }

    static func isTrainingWeekday(_ date: Date = Date()) -> Bool {
        dayKind(date) == .gym
    }

    static func pickWorkoutLetter(sessions: [WorkoutSession], date: Date = Date()) -> WorkoutLetter {
        let completed = sessions
            .filter(\.completed)
            .sorted { lhs, rhs in
                if lhs.dateKey != rhs.dateKey {
                    return lhs.dateKey > rhs.dateKey
                }
                return (lhs.finishedAt ?? lhs.startedAt) > (rhs.finishedAt ?? rhs.startedAt)
            }

        if let last = completed.first {
            return last.workout.opposite
        }

        return weekdayIndex(date) == 2 ? .B : .A
    }
}

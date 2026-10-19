import Foundation

enum ScheduleResolver {
    static func plan(
        on date: Date,
        schedule: WeeklySchedule,
        workouts: [WorkoutPlan]
    ) -> DayPlan {
        let map = Dictionary(uniqueKeysWithValues: workouts.map { ($0.id, $0) })
        if let id = schedule.workoutID(on: date), let workout = map[id] {
            return DayPlan(date: date, workout: workout)
        }
        return DayPlan(date: date, workout: nil)
    }

    /// True when at least one weekday still points at a workout that exists.
    static func hasLiveSchedule(schedule: WeeklySchedule, workouts: [WorkoutPlan]) -> Bool {
        guard !workouts.isEmpty else { return false }
        let ids = Set(workouts.map(\.id))
        return schedule.workoutIDs.contains { id in
            guard let id, !id.isEmpty else { return false }
            return ids.contains(id)
        }
    }

    static func status(
        on date: Date,
        schedule: WeeklySchedule,
        workouts: [WorkoutPlan]
    ) -> DayTrainingStatus {
        guard hasLiveSchedule(schedule: schedule, workouts: workouts) else {
            return .unconfigured
        }
        if let workout = plan(on: date, schedule: schedule, workouts: workouts).workout {
            return .training(workout)
        }
        return .rest
    }

    static func isTrainingDay(date: Date, schedule: WeeklySchedule) -> Bool {
        schedule.workoutID(on: date) != nil
    }

    /// Prefer the scheduled workout. If the user trains off-schedule, rotate
    /// through the program after the last completed session.
    static func pickWorkout(
        date: Date = Date(),
        schedule: WeeklySchedule,
        workouts: [WorkoutPlan],
        sessions: [SessionLog]
    ) -> WorkoutPlan? {
        let sorted = workouts.sorted { $0.sortOrder < $1.sortOrder }
        guard !sorted.isEmpty else { return nil }

        let planned = plan(on: date, schedule: schedule, workouts: sorted)
        if let workout = planned.workout {
            return workout
        }

        let completed = sessions
            .filter(\.completed)
            .sorted { lhs, rhs in
                if lhs.dateKey != rhs.dateKey {
                    return lhs.dateKey > rhs.dateKey
                }
                return (lhs.finishedAt ?? lhs.startedAt) > (rhs.finishedAt ?? rhs.startedAt)
            }

        guard let last = completed.first,
              let index = sorted.firstIndex(where: { $0.id == last.workoutID })
        else {
            return sorted[0]
        }
        return sorted[(index + 1) % sorted.count]
    }

    static func nextTrainingDate(
        from date: Date = Date(),
        schedule: WeeklySchedule
    ) -> Date? {
        if schedule.isEmpty { return nil }
        for offset in 0..<14 {
            let candidate = Dates.adding(days: offset, to: Dates.startOfDay(date))
            if schedule.workoutID(on: candidate) != nil {
                return candidate
            }
        }
        return nil
    }

    static func schedule(
        mapping: [(weekdayIndex: Int, workoutID: String)]
    ) -> WeeklySchedule {
        var ids: [String?] = Array(repeating: nil, count: 7)
        for item in mapping where (0..<7).contains(item.weekdayIndex) {
            ids[item.weekdayIndex] = item.workoutID
        }
        return WeeklySchedule(workoutIDs: ids)
    }
}

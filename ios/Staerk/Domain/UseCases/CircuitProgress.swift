import Foundation

enum CircuitProgress {
    struct Summary: Equatable, Sendable {
        var sessionsThisWeek: Int
        var scheduledThisWeek: Int
        var streak: Int
        var totalMinutes: Int
        var effortTrend: [EffortSample]
        var averageEffort: Double?
    }

    struct EffortSample: Equatable, Identifiable, Sendable {
        var id: String
        var dateKey: String
        var effort: Int
    }

    /// Sessions/week, training-day streak, total minutes, and effort trend.
    /// Streak and weekly count use every completed session (circuit or detailed)
    /// so a migrated LOOP user keeps credit for older A/B logs. Time and effort
    /// prefer circuit fields and fall back to elapsed session time.
    static func summary(
        sessions: [SessionLog],
        schedule: WeeklySchedule,
        today: String,
        weekKeys: [String]
    ) -> Summary {
        let completed = sessions.filter(\.completed)
        let completedKeys = Set(completed.map(\.dateKey))
        let weekCount = completed.filter { weekKeys.contains($0.dateKey) }.count
        let scheduledThisWeek = weekKeys.filter { key in
            schedule.workoutID(on: Dates.parse(key)) != nil
        }.count

        let streak = StreakCalculator.trainingStreak(
            today: today,
            schedule: schedule,
            completedDateKeys: completedKeys
        )

        let totalMinutes = completed.compactMap(\.resolvedDurationMinutes).reduce(0, +)
        let effortTrend = completed
            .sorted { lhs, rhs in
                if lhs.dateKey == rhs.dateKey {
                    return (lhs.finishedAt ?? lhs.startedAt) < (rhs.finishedAt ?? rhs.startedAt)
                }
                return lhs.dateKey < rhs.dateKey
            }
            .compactMap { session -> EffortSample? in
                guard let effort = EffortRating.clamped(session.effort) else { return nil }
                return EffortSample(id: session.id, dateKey: session.dateKey, effort: effort)
            }

        let average: Double?
        if effortTrend.isEmpty {
            average = nil
        } else {
            let total = effortTrend.map(\.effort).reduce(0, +)
            average = Double(total) / Double(effortTrend.count)
        }

        return Summary(
            sessionsThisWeek: weekCount,
            scheduledThisWeek: scheduledThisWeek,
            streak: streak,
            totalMinutes: totalMinutes,
            effortTrend: effortTrend,
            averageEffort: average
        )
    }

    static func lastCircuit(in sessions: [SessionLog], workoutID: String?) -> SessionLog? {
        sessions
            .filter { $0.completed && $0.isCircuit }
            .sorted { lhs, rhs in
                if lhs.dateKey != rhs.dateKey {
                    return lhs.dateKey > rhs.dateKey
                }
                return (lhs.finishedAt ?? lhs.startedAt) > (rhs.finishedAt ?? rhs.startedAt)
            }
            .first { workoutID == nil || $0.workoutID == workoutID }
            ?? sessions
                .filter { $0.completed && $0.isCircuit }
                .sorted { $0.dateKey > $1.dateKey }
                .first
    }
}

enum CircuitMigration {
    static let martinTemplateID = "tmpl_martin"
    static let loopTemplateID = "tmpl_loop"

    static func shouldConvert(program: TrainingProgram, workouts: [WorkoutPlan]) -> Bool {
        guard program.templateID == martinTemplateID || program.templateID == loopTemplateID else {
            return false
        }
        return !workouts.contains(where: \.isCircuit)
    }
}

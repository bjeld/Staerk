import Foundation

enum ProgressionCalculator {
    static func lastForExercise(sessions: [SessionLog], exerciseId: String) -> LastPerformance? {
        let hits = sessions
            .filter(\.completed)
            .sorted { lhs, rhs in
                if lhs.dateKey != rhs.dateKey {
                    return lhs.dateKey > rhs.dateKey
                }
                return (lhs.finishedAt ?? lhs.startedAt) > (rhs.finishedAt ?? rhs.startedAt)
            }

        for session in hits {
            guard let block = session.exercises.first(where: { $0.exerciseId == exerciseId }) else { continue }
            let done = block.sets.filter { $0.done && $0.reps > 0 }
            guard let first = done.first else { continue }
            let top = done.max(by: { $0.weightKg < $1.weightKg }) ?? first
            return LastPerformance(
                dateKey: session.dateKey,
                sets: done,
                topWeightKg: top.weightKg,
                topReps: top.reps
            )
        }
        return nil
    }

    static func suggestNext(exercise: ExerciseDefinition, last: LastPerformance?) -> ProgressionAdvice {
        guard let last else {
            if exercise.logType == .seconds {
                return .startSeconds(min: exercise.defaultRepsMin, max: exercise.defaultRepsMax)
            }
            return .startReps(min: exercise.defaultRepsMin, max: exercise.defaultRepsMax)
        }

        let allTopRange = last.sets.allSatisfy { $0.reps >= exercise.defaultRepsMax }
        let allInRange = last.sets.allSatisfy { $0.reps >= exercise.defaultRepsMin }
        let sameWeight = last.sets.allSatisfy { $0.weightKg == last.sets[0].weightKg }

        if exercise.logType == .seconds {
            if allTopRange {
                return .addSeconds
            }
            return .holdSeconds(min: exercise.defaultRepsMin, max: exercise.defaultRepsMax)
        }

        if allTopRange && sameWeight {
            let next = (last.topWeightKg + 2.5).rounded(toPlaces: 1)
            return .increaseWeight(fromKg: last.topWeightKg, toKg: next, repsMax: exercise.defaultRepsMax)
        }

        if allInRange {
            return .holdForMaxReps(weightKg: last.topWeightKg, maxReps: exercise.defaultRepsMax)
        }

        return .stayUntilMin(weightKg: last.topWeightKg, minReps: exercise.defaultRepsMin)
    }

    static func defaultSets(from last: LastPerformance?, exercise: ExerciseDefinition) -> SessionExerciseBlock {
        let weight = last?.topWeightKg ?? 0
        let reps: Int
        if let first = last?.sets.first {
            reps = first.reps
        } else {
            reps = Int((Double(exercise.defaultRepsMin + exercise.defaultRepsMax) / 2).rounded())
        }
        let sets = (0..<exercise.defaultSets).map { _ in
            SetLog(weightKg: weight, reps: reps, done: false)
        }
        return SessionExerciseBlock(
            exerciseId: exercise.id,
            name: exercise.name,
            muscleGroup: exercise.muscleGroup,
            logType: exercise.logType,
            sets: sets
        )
    }

    static func weeklySetVolume(
        sessions: [SessionLog],
        weekStart: String,
        weekEnd: String,
        muscleOf: (String) -> MuscleGroup?
    ) -> [MuscleGroup: Int] {
        var volume: [MuscleGroup: Int] = [:]
        for session in sessions where session.completed {
            guard session.dateKey >= weekStart, session.dateKey <= weekEnd else { continue }
            for block in session.exercises {
                let muscle = muscleOf(block.exerciseId) ?? block.muscleGroup
                volume[muscle, default: 0] += block.sets.filter(\.done).count
            }
        }
        return volume
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

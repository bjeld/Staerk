import Foundation

struct LastPerformance {
    var dateKey: String
    var sets: [SetLog]
    var topWeight: Double
    var topReps: Int
}

enum Progression {
    static func lastForExercise(sessions: [WorkoutSession], exerciseId: String) -> LastPerformance? {
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
            let top = done.max(by: { $0.weight < $1.weight }) ?? first
            return LastPerformance(
                dateKey: session.dateKey,
                sets: done,
                topWeight: top.weight,
                topReps: top.reps
            )
        }
        return nil
    }

    static func suggestNext(exercise: Exercise, last: LastPerformance?) -> String {
        guard let last else {
            if exercise.logType == .seconds {
                return "Start roligt: \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax) sek. Hold teknikken ren."
            }
            return "Find en vægt du kan løfte \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax) gange med 2 reps i reserve."
        }

        let allTopRange = last.sets.allSatisfy { $0.reps >= exercise.defaultRepsMax }
        let allInRange = last.sets.allSatisfy { $0.reps >= exercise.defaultRepsMin }
        let sameWeight = last.sets.allSatisfy { $0.weight == last.sets[0].weight }

        if exercise.logType == .seconds {
            if allTopRange {
                let joined = last.sets.map { "\($0.reps)s" }.joined(separator: ", ")
                return "Sidste gang \(joined). Prøv +5–10 sek."
            }
            return "Sigte efter \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax) sek. med rolig vejrtrækning."
        }

        if allTopRange && sameWeight {
            let next = (last.topWeight + 2.5).rounded(toPlaces: 1)
            return "Sidste gang \(last.topWeight.staerkWeight) kg × \(exercise.defaultRepsMax). Prøv \(next.staerkWeight) kg × \(exercise.defaultRepsMin)–\(exercise.defaultRepsMax)."
        }

        if allInRange {
            return "Hold \(last.topWeight.staerkWeight) kg og jag \(exercise.defaultRepsMax) reps i alle sæt, før du går op."
        }

        return "Bliv på \(last.topWeight.staerkWeight) kg. Få mindst \(exercise.defaultRepsMin) rene reps før du øger."
    }

    static func defaultSets(from last: LastPerformance?, exercise: Exercise) -> SessionExerciseBlock {
        let weight = last?.topWeight ?? 0
        let reps: Int
        if let first = last?.sets.first {
            reps = first.reps
        } else {
            reps = Int((Double(exercise.defaultRepsMin + exercise.defaultRepsMax) / 2).rounded())
        }
        let sets = (0..<exercise.defaultSets).map { _ in
            SetLog(weight: weight, reps: reps, done: false)
        }
        return SessionExerciseBlock(exerciseId: exercise.id, sets: sets)
    }

    static func weeklySetVolume(
        sessions: [WorkoutSession],
        weekStart: String,
        weekEnd: String,
        muscleOf: (String) -> MuscleGroup?
    ) -> [MuscleGroup: Int] {
        var volume: [MuscleGroup: Int] = [:]
        for session in sessions where session.completed {
            guard session.dateKey >= weekStart, session.dateKey <= weekEnd else { continue }
            for block in session.exercises {
                guard let muscle = muscleOf(block.exerciseId) else { continue }
                volume[muscle, default: 0] += block.sets.filter(\.done).count
            }
        }
        return volume
    }

    static func formatSet(exercise: Exercise, set: SetLog) -> String {
        if exercise.logType == .seconds {
            return "\(set.reps)s"
        }
        return "\(set.weight.staerkWeight) kg × \(set.reps)"
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

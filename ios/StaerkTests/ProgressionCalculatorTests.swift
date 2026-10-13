import XCTest
@testable import Staerk

final class ProgressionCalculatorTests: XCTestCase {
    private func exercise(logType: LogType = .reps, min: Int = 8, max: Int = 12) -> ExerciseDefinition {
        ExerciseDefinition(
            id: "ex1",
            workoutID: "w1",
            name: "Press",
            muscleGroup: .chest,
            defaultSets: 3,
            defaultRepsMin: min,
            defaultRepsMax: max,
            logType: logType
        )
    }

    func testIncreaseWhenAllSetsHitMax() {
        let last = LastPerformance(
            dateKey: "2026-10-01",
            sets: [
                SetLog(weightKg: 40, reps: 12, done: true),
                SetLog(weightKg: 40, reps: 12, done: true),
                SetLog(weightKg: 40, reps: 12, done: true)
            ],
            topWeightKg: 40,
            topReps: 12
        )
        let advice = ProgressionCalculator.suggestNext(exercise: exercise(), last: last)
        XCTAssertEqual(advice, .increaseWeight(fromKg: 40, toKg: 42.5, repsMax: 12))
    }

    func testHoldWhenInRangeButNotMax() {
        let last = LastPerformance(
            dateKey: "2026-10-01",
            sets: [
                SetLog(weightKg: 40, reps: 10, done: true),
                SetLog(weightKg: 40, reps: 9, done: true),
                SetLog(weightKg: 40, reps: 8, done: true)
            ],
            topWeightKg: 40,
            topReps: 10
        )
        let advice = ProgressionCalculator.suggestNext(exercise: exercise(), last: last)
        XCTAssertEqual(advice, .holdForMaxReps(weightKg: 40, maxReps: 12))
    }

    func testStayWhenBelowMin() {
        let last = LastPerformance(
            dateKey: "2026-10-01",
            sets: [
                SetLog(weightKg: 50, reps: 6, done: true),
                SetLog(weightKg: 50, reps: 5, done: true)
            ],
            topWeightKg: 50,
            topReps: 6
        )
        let advice = ProgressionCalculator.suggestNext(exercise: exercise(), last: last)
        XCTAssertEqual(advice, .stayUntilMin(weightKg: 50, minReps: 8))
    }

    func testDefaultSetsUseLastWeight() {
        let last = LastPerformance(
            dateKey: "2026-10-01",
            sets: [SetLog(weightKg: 32.5, reps: 10, done: true)],
            topWeightKg: 32.5,
            topReps: 10
        )
        let block = ProgressionCalculator.defaultSets(from: last, exercise: exercise())
        XCTAssertEqual(block.sets.count, 3)
        XCTAssertEqual(block.sets.first?.weightKg, 32.5)
        XCTAssertFalse(block.sets.contains(where: \.done))
    }

    func testLastForExerciseIgnoresIncompleteSets() {
        let sessions = [
            SessionLog(
                dateKey: "2026-10-10",
                workoutID: "w",
                workoutName: "A",
                completed: true,
                exercises: [
                    SessionExerciseBlock(
                        exerciseId: "ex1",
                        sets: [SetLog(weightKg: 20, reps: 0, done: true)]
                    )
                ]
            ),
            SessionLog(
                dateKey: "2026-10-08",
                workoutID: "w",
                workoutName: "A",
                completed: true,
                exercises: [
                    SessionExerciseBlock(
                        exerciseId: "ex1",
                        sets: [SetLog(weightKg: 30, reps: 8, done: true)]
                    )
                ]
            )
        ]
        let last = ProgressionCalculator.lastForExercise(sessions: sessions, exerciseId: "ex1")
        XCTAssertEqual(last?.topWeightKg, 30)
    }
}

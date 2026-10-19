import XCTest
@testable import Staerk

final class CircuitProgressTests: XCTestCase {
    private let monday = "2026-10-12"
    private let wednesday = "2026-10-14"
    private let friday = "2026-10-16"
    private let tuesday = "2026-10-13"

    private func loopSchedule(workoutID: String = "loop") -> WeeklySchedule {
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[0] = workoutID
        ids[2] = workoutID
        ids[4] = workoutID
        return WeeklySchedule(workoutIDs: ids)
    }

    private func session(
        dateKey: String,
        completed: Bool = true,
        kind: WorkoutKind = .circuit,
        durationMinutes: Int? = 30,
        effort: Int? = nil,
        startedAt: Date? = nil,
        finishedAt: Date? = nil
    ) -> SessionLog {
        let start = startedAt ?? Dates.parse(dateKey)
        return SessionLog(
            dateKey: dateKey,
            workoutID: "loop",
            workoutName: "LOOP",
            completed: completed,
            startedAt: start,
            finishedAt: finishedAt,
            exercises: [],
            kind: kind,
            durationMinutes: durationMinutes,
            rounds: 2,
            effort: effort
        )
    }

    func testWeeklyCountAndScheduledDays() {
        let week = Dates.weekKeys(of: Dates.parse(wednesday))
        let summary = CircuitProgress.summary(
            sessions: [
                session(dateKey: monday, effort: 3),
                session(dateKey: wednesday, effort: 4)
            ],
            schedule: loopSchedule(),
            today: wednesday,
            weekKeys: week
        )
        XCTAssertEqual(summary.sessionsThisWeek, 2)
        XCTAssertEqual(summary.scheduledThisWeek, 3)
        XCTAssertEqual(summary.totalMinutes, 60)
        XCTAssertEqual(summary.averageEffort, 3.5, accuracy: 0.01)
        XCTAssertEqual(summary.effortTrend.map(\.effort), [3, 4])
    }

    func testStreakSkipsRestDaysAndIncompleteToday() {
        let week = Dates.weekKeys(of: Dates.parse(friday))
        let summary = CircuitProgress.summary(
            sessions: [
                session(dateKey: monday),
                session(dateKey: wednesday)
            ],
            schedule: loopSchedule(),
            today: friday,
            weekKeys: week
        )
        XCTAssertEqual(summary.streak, 2)
    }

    func testStreakIncludesCompletedToday() {
        let week = Dates.weekKeys(of: Dates.parse(friday))
        let summary = CircuitProgress.summary(
            sessions: [
                session(dateKey: monday),
                session(dateKey: wednesday),
                session(dateKey: friday)
            ],
            schedule: loopSchedule(),
            today: friday,
            weekKeys: week
        )
        XCTAssertEqual(summary.streak, 3)
    }

    func testBrokenStreakStopsAtMissedTrainingDay() {
        let week = Dates.weekKeys(of: Dates.parse(friday))
        let summary = CircuitProgress.summary(
            sessions: [
                session(dateKey: friday)
            ],
            schedule: loopSchedule(),
            today: friday,
            weekKeys: week
        )
        XCTAssertEqual(summary.streak, 1)
    }

    func testLegacyDetailedSessionsCountTowardStreakAndWeek() {
        let week = Dates.weekKeys(of: Dates.parse(monday))
        let summary = CircuitProgress.summary(
            sessions: [
                session(dateKey: monday, kind: .detailed, durationMinutes: nil)
            ],
            schedule: loopSchedule(),
            today: monday,
            weekKeys: week
        )
        XCTAssertEqual(summary.sessionsThisWeek, 1)
        XCTAssertEqual(summary.streak, 1)
    }

    func testElapsedTimeUsedWhenDurationMissing() {
        let start = Dates.parse(monday)
        let end = start.addingTimeInterval(45 * 60)
        let log = session(
            dateKey: monday,
            durationMinutes: nil,
            startedAt: start,
            finishedAt: end
        )
        XCTAssertEqual(log.resolvedDurationMinutes, 45)
        let week = Dates.weekKeys(of: start)
        let summary = CircuitProgress.summary(
            sessions: [log],
            schedule: loopSchedule(),
            today: monday,
            weekKeys: week
        )
        XCTAssertEqual(summary.totalMinutes, 45)
    }

    func testEffortClampIgnoresOutOfRange() {
        XCTAssertNil(EffortRating.clamped(0))
        XCTAssertNil(EffortRating.clamped(6))
        XCTAssertEqual(EffortRating.clamped(5), 5)
        let log = session(dateKey: monday, effort: 9)
        XCTAssertNil(log.effort)
    }

    func testLastCircuitPrefersMatchingWorkout() {
        let older = SessionLog(
            dateKey: monday,
            workoutID: "loop",
            workoutName: "LOOP",
            completed: true,
            exercises: [],
            kind: .circuit,
            durationMinutes: 25
        )
        let newerOther = SessionLog(
            dateKey: wednesday,
            workoutID: "other",
            workoutName: "Other",
            completed: true,
            exercises: [],
            kind: .circuit,
            durationMinutes: 40
        )
        let last = CircuitProgress.lastCircuit(in: [older, newerOther], workoutID: "loop")
        XCTAssertEqual(last?.durationMinutes, 25)
    }
}

final class CircuitMigrationTests: XCTestCase {
    func testMartinDetailedProgramShouldConvert() {
        let program = TrainingProgram(name: "Martin", templateID: CircuitMigration.martinTemplateID)
        let workout = WorkoutPlan(programID: program.id, name: "A")
        XCTAssertTrue(CircuitMigration.shouldConvert(program: program, workouts: [workout]))
    }

    func testAlreadyCircuitDoesNotConvert() {
        let program = TrainingProgram(name: "Martin", templateID: CircuitMigration.martinTemplateID)
        let workout = WorkoutPlan(programID: program.id, name: "LOOP", kind: .circuit)
        XCTAssertFalse(CircuitMigration.shouldConvert(program: program, workouts: [workout]))
    }

    func testCustomProgramDoesNotConvert() {
        let program = TrainingProgram(name: "Mine")
        let workout = WorkoutPlan(programID: program.id, name: "A")
        XCTAssertFalse(CircuitMigration.shouldConvert(program: program, workouts: [workout]))
    }

    func testLoopTemplateMaterializesCircuitOnTrainingDays() {
        let packed = ProgramCatalog.materialize(ProgramCatalog.loop)
        XCTAssertEqual(packed.workouts.count, 1)
        XCTAssertTrue(packed.workouts[0].isCircuit)
        XCTAssertEqual(packed.workouts[0].stations.count, 10)
        XCTAssertEqual(packed.workouts[0].targetRounds, 2)
        XCTAssertEqual(packed.workouts[0].targetDurationMinutes, 30)
        XCTAssertEqual(packed.schedule.workoutIDs[0], packed.workouts[0].id)
        XCTAssertNil(packed.schedule.workoutIDs[1])
        XCTAssertEqual(packed.schedule.workoutIDs[2], packed.workouts[0].id)
        XCTAssertEqual(packed.schedule.workoutIDs[4], packed.workouts[0].id)
        XCTAssertEqual(packed.schedule.trainingWeekdays, .trainingDefault)
    }

    func testMartinTemplateIsLoopCircuit() {
        let packed = ProgramCatalog.materialize(ProgramCatalog.martin)
        XCTAssertEqual(packed.program.templateID, CircuitMigration.martinTemplateID)
        XCTAssertEqual(packed.workouts.count, 1)
        XCTAssertTrue(packed.workouts[0].isCircuit)
        XCTAssertTrue(packed.exercises.isEmpty)
        XCTAssertEqual(packed.schedule.trainingWeekdays, .trainingDefault)
    }

    func testMaterializeKeepsProgramIdentity() {
        let packed = ProgramCatalog.materialize(
            ProgramCatalog.martin,
            programID: "prg_keep",
            name: "Martins setup"
        )
        XCTAssertEqual(packed.program.id, "prg_keep")
        XCTAssertEqual(packed.program.name, "Martins setup")
        XCTAssertEqual(packed.workouts.first?.programID, "prg_keep")
    }

    func testOldSessionJSONDefaultsToDetailed() throws {
        let json = """
        {"id":"s1","dateKey":"2026-10-01","workoutID":"w","workoutName":"A","completed":true,"exercises":[]}
        """.data(using: .utf8)!
        let session = try JSONDecoder().decode(SessionLog.self, from: json)
        XCTAssertEqual(session.kind, .detailed)
        XCTAssertNil(session.durationMinutes)
        XCTAssertFalse(session.isCircuit)
    }

    func testOldWorkoutJSONDefaultsToDetailed() throws {
        let json = """
        {"id":"w1","programID":"p","name":"A","sortOrder":0}
        """.data(using: .utf8)!
        let workout = try JSONDecoder().decode(WorkoutPlan.self, from: json)
        XCTAssertEqual(workout.kind, .detailed)
        XCTAssertTrue(workout.stations.isEmpty)
    }
}

final class TrainingStreakTests: XCTestCase {
    func testTrainingStreakUsesScheduleNotCalendarDays() {
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[0] = "loop"
        ids[2] = "loop"
        ids[4] = "loop"
        let schedule = WeeklySchedule(workoutIDs: ids)
        let streak = StreakCalculator.trainingStreak(
            today: "2026-10-14",
            schedule: schedule,
            completedDateKeys: ["2026-10-12", "2026-10-14"]
        )
        XCTAssertEqual(streak, 2)
    }
}

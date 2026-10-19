import XCTest
@testable import Staerk

final class ScheduleResolverTests: XCTestCase {
    func testPlanUsesScheduledWorkout() {
        let a = WorkoutPlan(id: "a", programID: "p", name: "A", sortOrder: 0)
        let b = WorkoutPlan(id: "b", programID: "p", name: "B", sortOrder: 1)
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[0] = "a"
        ids[2] = "b"
        ids[4] = "a"
        let schedule = WeeklySchedule(workoutIDs: ids)
        let monday = Dates.parse("2026-10-12")
        let wednesday = Dates.parse("2026-10-14")
        let tuesday = Dates.parse("2026-10-13")
        XCTAssertEqual(ScheduleResolver.plan(on: monday, schedule: schedule, workouts: [a, b]).workout?.id, "a")
        XCTAssertEqual(ScheduleResolver.plan(on: wednesday, schedule: schedule, workouts: [a, b]).workout?.id, "b")
        XCTAssertNil(ScheduleResolver.plan(on: tuesday, schedule: schedule, workouts: [a, b]).workout)
    }

    func testOffScheduleRotatesAfterLastSession() {
        let a = WorkoutPlan(id: "a", programID: "p", name: "A", sortOrder: 0)
        let b = WorkoutPlan(id: "b", programID: "p", name: "B", sortOrder: 1)
        let schedule = WeeklySchedule()
        let sessions = [
            SessionLog(dateKey: "2026-10-12", workoutID: "a", workoutName: "A", completed: true, exercises: [])
        ]
        let picked = ScheduleResolver.pickWorkout(
            date: Dates.parse("2026-10-13"),
            schedule: schedule,
            workouts: [a, b],
            sessions: sessions
        )
        XCTAssertEqual(picked?.id, "b")
    }

    func testNextTrainingDateSkipsRestDays() {
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[2] = "a"
        let schedule = WeeklySchedule(workoutIDs: ids)
        let tuesday = Dates.parse("2026-10-13")
        let next = ScheduleResolver.nextTrainingDate(from: tuesday, schedule: schedule)
        XCTAssertEqual(Dates.key(next ?? Date()), "2026-10-14")
    }

    func testEmptyScheduleHasNoTrainingDay() {
        XCTAssertFalse(ScheduleResolver.isTrainingDay(date: Date(), schedule: WeeklySchedule()))
        XCTAssertNil(ScheduleResolver.nextTrainingDate(schedule: WeeklySchedule()))
    }

    func testStatusUnconfiguredWithoutWorkoutsEvenIfScheduleRemains() {
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[0] = "gone"
        let schedule = WeeklySchedule(workoutIDs: ids)
        let monday = Dates.parse("2026-10-12")
        XCTAssertFalse(ScheduleResolver.hasLiveSchedule(schedule: schedule, workouts: []))
        XCTAssertEqual(ScheduleResolver.status(on: monday, schedule: schedule, workouts: []), .unconfigured)
    }

    func testStatusUnconfiguredWithoutScheduledWorkouts() {
        let workout = WorkoutPlan(id: "a", programID: "p", name: "A", sortOrder: 0)
        XCTAssertFalse(ScheduleResolver.hasLiveSchedule(schedule: WeeklySchedule(), workouts: [workout]))
        XCTAssertEqual(
            ScheduleResolver.status(on: Date(), schedule: WeeklySchedule(), workouts: [workout]),
            .unconfigured
        )
    }

    func testStatusRestOnNonTrainingDayWithLiveSchedule() {
        let workout = WorkoutPlan(id: "a", programID: "p", name: "A", sortOrder: 0)
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[0] = "a"
        let schedule = WeeklySchedule(workoutIDs: ids)
        let tuesday = Dates.parse("2026-10-13")
        XCTAssertEqual(
            ScheduleResolver.status(on: tuesday, schedule: schedule, workouts: [workout]),
            .rest
        )
    }

    func testStatusTrainingWhenScheduledWorkoutExists() {
        let workout = WorkoutPlan(id: "a", programID: "p", name: "A", sortOrder: 0)
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[0] = "a"
        let schedule = WeeklySchedule(workoutIDs: ids)
        let monday = Dates.parse("2026-10-12")
        XCTAssertEqual(
            ScheduleResolver.status(on: monday, schedule: schedule, workouts: [workout]),
            .training(workout)
        )
    }

    func testStatusIgnoresStaleScheduleIDsWithoutLiveWorkouts() {
        let workout = WorkoutPlan(id: "a", programID: "p", name: "A", sortOrder: 0)
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[0] = "gone"
        let schedule = WeeklySchedule(workoutIDs: ids)
        XCTAssertFalse(ScheduleResolver.hasLiveSchedule(schedule: schedule, workouts: [workout]))
        XCTAssertEqual(
            ScheduleResolver.status(on: Dates.parse("2026-10-12"), schedule: schedule, workouts: [workout]),
            .unconfigured
        )
    }

    func testHasLiveScheduleWhenAtLeastOneMappedWorkoutExists() {
        let workout = WorkoutPlan(id: "a", programID: "p", name: "A", sortOrder: 0)
        var ids: [String?] = Array(repeating: nil, count: 7)
        ids[0] = "gone"
        ids[2] = "a"
        XCTAssertTrue(ScheduleResolver.hasLiveSchedule(
            schedule: WeeklySchedule(workoutIDs: ids),
            workouts: [workout]
        ))
    }
}

import XCTest
@testable import Staerk

final class HabitScoringTests: XCTestCase {
    func testCounterCompletesAtGoal() {
        let habit = Habit(id: "w", name: "Water", kind: .counter, symbol: "drop.fill", goal: 8)
        XCTAssertFalse(HabitScoring.isComplete(habit: habit, entry: HabitEntry(habitID: "w", dateKey: "d", countValue: 7), trained: false))
        XCTAssertTrue(HabitScoring.isComplete(habit: habit, entry: HabitEntry(habitID: "w", dateKey: "d", countValue: 8), trained: false))
    }

    func testWorkoutCompleteFromSessionOrToggle() {
        let habit = Habit(id: "t", name: "Train", kind: .workout, symbol: "dumbbell.fill")
        XCTAssertTrue(HabitScoring.isComplete(habit: habit, entry: nil, trained: true))
        XCTAssertTrue(HabitScoring.isComplete(habit: habit, entry: HabitEntry(habitID: "t", dateKey: "d", boolValue: true), trained: false))
        XCTAssertFalse(HabitScoring.isComplete(habit: habit, entry: nil, trained: false))
    }

    func testDayRatioIgnoresNonApplicableHabits() {
        var daily = Habit(id: "d", name: "Daily", kind: .boolean, symbol: "star", weekdays: .all)
        daily.id = "d"
        let weekend = Habit(id: "g", name: "Golf", kind: .boolean, symbol: "flag", weekdays: .weekend)
        let monday = "2026-10-12"
        let entries = [HabitEntry(habitID: "d", dateKey: monday, boolValue: true)]
        let ratio = HabitScoring.dayRatio(habits: [daily, weekend], entries: entries, trained: false, dateKey: monday)
        XCTAssertEqual(ratio, 1)
    }

    func testWeekScoreCountsApplicableSlots() {
        let habit = Habit(id: "c", name: "Creatine", kind: .boolean, symbol: "pills.fill", weekdays: .all)
        let week = Dates.weekKeys(of: Dates.parse("2026-10-12"))
        let entries = week.prefix(3).map { HabitEntry(habitID: "c", dateKey: $0, boolValue: true) }
        let score = HabitScoring.weekCompletedCount(habits: [habit], entries: entries, trainedDates: [], week: week)
        XCTAssertEqual(score.total, 7)
        XCTAssertEqual(score.done, 3)
    }

    func testRefreshesLegacyDefaultNotes() {
        var habit = HabitCatalog.make(.creatine, sortOrder: 0)
        habit.notes = "5 g med morgenkaffen eller efter træning"
        let updated = HabitCatalog.refreshedNotes(habit)
        XCTAssertEqual(updated.notes, HabitCatalog.defaultNotes(for: "tmpl_creatine"))
        XCTAssertNotEqual(updated.notes, habit.notes)
    }

    func testLeavesCustomHabitNotesAlone() {
        var habit = HabitCatalog.make(.creatine, sortOrder: 0)
        habit.notes = "Min egen note"
        XCTAssertEqual(HabitCatalog.refreshedNotes(habit).notes, "Min egen note")
    }

    func testDoesNotRefreshUnknownTemplate() {
        let habit = Habit(name: "Custom", kind: .boolean, symbol: "star", notes: "5 g med morgenkaffen eller efter træning")
        XCTAssertEqual(HabitCatalog.refreshedNotes(habit).notes, habit.notes)
    }

    func testHidesWorkoutHabitsWhenNoWorkoutsExist() {
        let workout = Habit(id: "t", name: "Train", kind: .workout, symbol: "dumbbell.fill")
        let water = Habit(id: "w", name: "Water", kind: .counter, symbol: "drop.fill", goal: 8)
        let hidden = HabitScoring.excludingDanglingWorkoutHabits([workout, water], hasWorkouts: false)
        XCTAssertEqual(hidden.map(\.id), ["w"])
        XCTAssertEqual(
            HabitScoring.excludingDanglingWorkoutHabits([workout, water], hasWorkouts: true).map(\.id),
            ["t", "w"]
        )
    }

    func testDayRatioIgnoresDanglingWorkoutHabits() {
        let workout = Habit(id: "t", name: "Train", kind: .workout, symbol: "dumbbell.fill", weekdays: .all)
        let water = Habit(id: "w", name: "Water", kind: .boolean, symbol: "drop.fill", weekdays: .all)
        let monday = "2026-10-12"
        let entries = [HabitEntry(habitID: "w", dateKey: monday, boolValue: true)]
        let visible = HabitScoring.excludingDanglingWorkoutHabits([workout, water], hasWorkouts: false)
        XCTAssertEqual(
            HabitScoring.dayRatio(habits: visible, entries: entries, trained: false, dateKey: monday),
            1
        )
        XCTAssertEqual(
            HabitScoring.dayRatio(habits: [workout, water], entries: entries, trained: false, dateKey: monday),
            0.5
        )
    }
}

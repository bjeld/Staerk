import XCTest
@testable import Staerk

final class StreakCalculatorTests: XCTestCase {
    func testStreakCountsApplicableDaysOnly() {
        let habit = Habit(
            id: "h1",
            name: "Train",
            kind: .workout,
            symbol: "dumbbell.fill",
            weekdays: .trainingDefault
        )
        let today = "2026-10-12" // Monday
        let entries = [
            HabitEntry(habitID: "h1", dateKey: "2026-10-12", boolValue: true),
            HabitEntry(habitID: "h1", dateKey: "2026-10-10", boolValue: true),
            HabitEntry(habitID: "h1", dateKey: "2026-10-09", boolValue: true), // Thursday — not applicable
            HabitEntry(habitID: "h1", dateKey: "2026-10-08", boolValue: true)
        ]
        let streak = StreakCalculator.habitStreak(habit: habit, entries: entries, today: today)
        XCTAssertEqual(streak, 3)
    }

    func testIncompleteTodayDoesNotBreakStreak() {
        let habit = Habit(id: "h1", name: "Water", kind: .counter, symbol: "drop.fill", goal: 8)
        let today = "2026-10-13"
        let entries = [
            HabitEntry(habitID: "h1", dateKey: "2026-10-12", countValue: 8),
            HabitEntry(habitID: "h1", dateKey: "2026-10-11", countValue: 8)
        ]
        let streak = StreakCalculator.habitStreak(habit: habit, entries: entries, today: today)
        XCTAssertEqual(streak, 2)
    }

    func testBrokenStreakStops() {
        let habit = Habit(id: "h1", name: "Pills", kind: .boolean, symbol: "pills.fill")
        let today = "2026-10-13"
        let entries = [
            HabitEntry(habitID: "h1", dateKey: "2026-10-13", boolValue: true),
            HabitEntry(habitID: "h1", dateKey: "2026-10-11", boolValue: true)
        ]
        let streak = StreakCalculator.habitStreak(habit: habit, entries: entries, today: today)
        XCTAssertEqual(streak, 1)
    }

    func testWorkoutHabitCountsCompletedSession() {
        let habit = Habit(id: "h1", name: "Gym", kind: .workout, symbol: "dumbbell.fill", weekdays: .trainingDefault)
        let today = "2026-10-12"
        let sessions = [
            SessionLog(dateKey: "2026-10-12", workoutID: "w", workoutName: "A", completed: true, exercises: [])
        ]
        let streak = StreakCalculator.habitStreak(habit: habit, entries: [], sessions: sessions, today: today)
        XCTAssertEqual(streak, 1)
    }
}

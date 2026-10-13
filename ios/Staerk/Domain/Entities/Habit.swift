import Foundation

struct Habit: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var name: String
    var kind: HabitKind
    var symbol: String
    var tintHex: String
    var weekdays: WeekdaySet
    var goal: Int
    var reminderEnabled: Bool
    var reminderTime: String
    var sortOrder: Int
    var archived: Bool
    var notes: String
    var templateID: String?

    init(
        id: String = StaerkID.make("hab"),
        name: String,
        kind: HabitKind,
        symbol: String,
        tintHex: String = "C6FF00",
        weekdays: WeekdaySet = .all,
        goal: Int = 1,
        reminderEnabled: Bool = false,
        reminderTime: String = "07:00",
        sortOrder: Int = 0,
        archived: Bool = false,
        notes: String = "",
        templateID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.symbol = symbol
        self.tintHex = tintHex
        self.weekdays = weekdays
        self.goal = max(1, goal)
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.sortOrder = sortOrder
        self.archived = archived
        self.notes = notes
        self.templateID = templateID
    }

    func applies(on date: Date) -> Bool {
        weekdays.contains(index: Dates.weekdayIndex(date))
    }

    func applies(onKey key: String) -> Bool {
        weekdays.contains(index: Dates.weekdayIndex(key: key))
    }
}

struct HabitEntry: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var habitID: String
    var dateKey: String
    var boolValue: Bool
    var countValue: Int

    init(
        id: String = StaerkID.make("ent"),
        habitID: String,
        dateKey: String,
        boolValue: Bool = false,
        countValue: Int = 0
    ) {
        self.id = id
        self.habitID = habitID
        self.dateKey = dateKey
        self.boolValue = boolValue
        self.countValue = countValue
    }
}

struct HabitTemplate: Identifiable, Hashable, Sendable {
    var id: String
    var nameKey: String
    var notesKey: String
    var kind: HabitKind
    var symbol: String
    var tintHex: String
    var weekdays: WeekdaySet
    var goal: Int
    var reminderEnabled: Bool
    var reminderTime: String

    func makeHabit(sortOrder: Int, localizedName: String, localizedNotes: String) -> Habit {
        Habit(
            name: localizedName,
            kind: kind,
            symbol: symbol,
            tintHex: tintHex,
            weekdays: weekdays,
            goal: goal,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            sortOrder: sortOrder,
            notes: localizedNotes,
            templateID: id
        )
    }
}

import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case legs
    case chest
    case back
    case shoulders
    case arms
    case core

    var id: String { rawValue }

    var localizationKey: String { "muscle.\(rawValue)" }

    var symbol: String {
        switch self {
        case .legs: return "figure.strengthtraining.traditional"
        case .chest: return "heart.fill"
        case .back: return "figure.cooldown"
        case .shoulders: return "figure.boxing"
        case .arms: return "dumbbell.fill"
        case .core: return "flame.fill"
        }
    }
}

enum LogType: String, Codable, CaseIterable, Identifiable, Hashable {
    case reps
    case seconds

    var id: String { rawValue }

    var localizationKey: String { "logtype.\(rawValue)" }
}

enum WorkoutKind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case detailed
    case circuit

    var id: String { rawValue }

    var localizationKey: String { "workout.kind.\(rawValue)" }

    var isCircuit: Bool { self == .circuit }
}

enum EffortRating {
    static let range = 1...5

    static func clamped(_ value: Int?) -> Int? {
        guard let value, range.contains(value) else { return nil }
        return value
    }

    static func localizationKey(_ value: Int) -> String {
        "effort.\(value)"
    }
}

enum ThemeMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var localizationKey: String { "theme.\(rawValue)" }
}

enum HabitKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case boolean
    case counter
    case workout

    var id: String { rawValue }

    var localizationKey: String { "habit.kind.\(rawValue)" }

    var defaultSymbol: String {
        switch self {
        case .boolean: return "checkmark.circle.fill"
        case .counter: return "plus.circle.fill"
        case .workout: return "dumbbell.fill"
        }
    }
}

struct WeekdaySet: OptionSet, Codable, Hashable, Sendable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let monday = WeekdaySet(rawValue: 1 << 0)
    static let tuesday = WeekdaySet(rawValue: 1 << 1)
    static let wednesday = WeekdaySet(rawValue: 1 << 2)
    static let thursday = WeekdaySet(rawValue: 1 << 3)
    static let friday = WeekdaySet(rawValue: 1 << 4)
    static let saturday = WeekdaySet(rawValue: 1 << 5)
    static let sunday = WeekdaySet(rawValue: 1 << 6)

    static let weekdays: WeekdaySet = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekend: WeekdaySet = [.saturday, .sunday]
    static let all: WeekdaySet = [.weekdays, .weekend]
    static let trainingDefault: WeekdaySet = [.monday, .wednesday, .friday]

    static let ordered: [WeekdaySet] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var mondayFirstIndices: [Int] {
        Self.ordered.enumerated().compactMap { index, day in
            contains(day) ? index : nil
        }
    }

    func contains(index: Int) -> Bool {
        guard Self.ordered.indices.contains(index) else { return false }
        return contains(Self.ordered[index])
    }

    mutating func toggle(index: Int) {
        guard Self.ordered.indices.contains(index) else { return }
        formSymmetricDifference(Self.ordered[index])
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum WeekdayLabel {
    static var shortKeys: [String] {
        [
            "weekday.mon.short",
            "weekday.tue.short",
            "weekday.wed.short",
            "weekday.thu.short",
            "weekday.fri.short",
            "weekday.sat.short",
            "weekday.sun.short"
        ]
    }

    static var longKeys: [String] {
        [
            "weekday.mon.long",
            "weekday.tue.long",
            "weekday.wed.long",
            "weekday.thu.long",
            "weekday.fri.long",
            "weekday.sat.long",
            "weekday.sun.long"
        ]
    }
}

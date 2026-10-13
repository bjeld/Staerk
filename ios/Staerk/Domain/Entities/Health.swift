import Foundation

struct TodayHealth: Equatable, Sendable {
    var steps: Double?
    var distanceKm: Double?
    var activeEnergyKcal: Double?
    var latestBodyMassKg: Double?
    var workouts: [HealthWorkoutSummary] = []
    var golfMinutes: Int?
    var walkMinutes: Int?

    var hasActivity: Bool {
        (steps ?? 0) > 0 || (distanceKm ?? 0) > 0 || (activeEnergyKcal ?? 0) > 0 || !workouts.isEmpty
    }
}

struct HealthWorkoutSummary: Identifiable, Equatable, Hashable, Sendable {
    var id: UUID
    var kind: Kind
    var start: Date
    var durationMinutes: Int
    var kcal: Double?
    var distanceKm: Double?

    enum Kind: String, Equatable, Sendable {
        case golf
        case walking
        case running
        case strength
        case other

        var titleKey: String { "health.kind.\(rawValue)" }

        var symbol: String {
            switch self {
            case .golf: return "figure.golf"
            case .walking: return "figure.walk"
            case .running: return "figure.run"
            case .strength: return "dumbbell.fill"
            case .other: return "heart.fill"
            }
        }
    }
}

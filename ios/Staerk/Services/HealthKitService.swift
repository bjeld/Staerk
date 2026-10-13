import Foundation
import HealthKit
import Observation

struct TodayHealth: Equatable {
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

struct HealthWorkoutSummary: Identifiable, Equatable, Hashable {
    var id: UUID
    var kind: Kind
    var start: Date
    var durationMinutes: Int
    var kcal: Double?
    var distanceKm: Double?

    enum Kind: String, Equatable {
        case golf
        case walking
        case running
        case strength
        case other

        var title: String {
            switch self {
            case .golf: return "Golf"
            case .walking: return "Gåtur"
            case .running: return "Løb"
            case .strength: return "Styrketræning"
            case .other: return "Træning"
            }
        }

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

@MainActor
@Observable
final class HealthKitService {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var didRequestAuthorization = UserDefaults.standard.bool(forKey: HealthKitService.requestedKey)
    var lastError: String?
    var isRefreshing = false
    var today = TodayHealth()
    var writeAuthorized = false

    private static let requestedKey = "staerk.health.requested"

    var authorizationStatus: HKAuthorizationStatus {
        store.authorizationStatus(for: HKObjectType.workoutType())
    }

    var showsPermissionPrompt: Bool {
        isAvailable && !didRequestAuthorization
    }

    var showsDeniedHelp: Bool {
        isAvailable && didRequestAuthorization && authorizationStatus == .sharingDenied
    }

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass),
            HKObjectType.workoutType(),
        ]
    }

    private var shareTypes: Set<HKSampleType> {
        [
            HKObjectType.workoutType(),
            HKQuantityType(.bodyMass),
        ]
    }

    func requestAccess() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            didRequestAuthorization = true
            UserDefaults.standard.set(true, forKey: Self.requestedKey)
            writeAuthorized = store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
            await refreshToday()
        } catch {
            lastError = error.localizedDescription
            didRequestAuthorization = true
            UserDefaults.standard.set(true, forKey: Self.requestedKey)
        }
    }

    func refreshToday() async {
        guard isAvailable, didRequestAuthorization else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        writeAuthorized = store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized

        async let steps = sumToday(type: HKQuantityType(.stepCount), unit: .count())
        async let distance = sumToday(type: HKQuantityType(.distanceWalkingRunning), unit: .meter())
        async let energy = sumToday(type: HKQuantityType(.activeEnergyBurned), unit: .kilocalorie())
        async let mass = latestBodyMass()
        async let workouts = workoutsToday()

        let stepValue = await steps
        let distanceMeters = await distance
        let kcal = await energy
        let bodyMass = await mass
        let sessionList = await workouts

        let golf = sessionList.filter { $0.kind == .golf }.reduce(0) { $0 + $1.durationMinutes }
        let walk = sessionList.filter { $0.kind == .walking || $0.kind == .running }.reduce(0) { $0 + $1.durationMinutes }

        today = TodayHealth(
            steps: stepValue,
            distanceKm: distanceMeters.map { $0 / 1000 },
            activeEnergyKcal: kcal,
            latestBodyMassKg: bodyMass,
            workouts: sessionList,
            golfMinutes: golf > 0 ? golf : nil,
            walkMinutes: walk > 0 ? walk : nil
        )
    }

    func saveStrengthWorkout(start: Date, end: Date) async {
        guard isAvailable else { return }
        guard store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.addMetadata([
                HKMetadataKeyWorkoutBrandName: "Styrke",
                HKMetadataKeyIndoorWorkout: true,
            ])
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func saveBodyMass(kg: Double, at date: Date) async {
        guard isAvailable else { return }
        let type = HKQuantityType(.bodyMass)
        guard store.authorizationStatus(for: type) == .sharingAuthorized else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        do {
            try await store.save(sample)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sumToday(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let start = Dates.startOfDay()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),
            options: .cumulativeSum
        )
        do {
            let stats = try await descriptor.result(for: store)
            return stats?.sumQuantity()?.doubleValue(for: unit)
        } catch {
            return nil
        }
    }

    private func latestBodyMass() async -> Double? {
        let type = HKQuantityType(.bodyMass)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)],
            limit: 1
        )
        do {
            let samples: [HKQuantitySample] = try await descriptor.result(for: store)
            return samples.first?.quantity.doubleValue(for: .gramUnit(with: .kilo))
        } catch {
            return nil
        }
    }

    private func workoutsToday() async -> [HealthWorkoutSummary] {
        let start = Dates.startOfDay()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\HKWorkout.startDate, order: .forward)],
            limit: 40
        )
        do {
            let workouts: [HKWorkout] = try await descriptor.result(for: store)
            return workouts.map { workout in
                HealthWorkoutSummary(
                    id: workout.uuid,
                    kind: Self.kind(for: workout.workoutActivityType),
                    start: workout.startDate,
                    durationMinutes: max(1, Int((workout.duration / 60).rounded())),
                    kcal: workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
                        .sumQuantity()?
                        .doubleValue(for: .kilocalorie()),
                    distanceKm: workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?
                        .sumQuantity()?
                        .doubleValue(for: .meterUnit(with: .kilo))
                )
            }
        } catch {
            return []
        }
    }

    private static func kind(for type: HKWorkoutActivityType) -> HealthWorkoutSummary.Kind {
        switch type {
        case .golf: return .golf
        case .walking: return .walking
        case .running: return .running
        case .traditionalStrengthTraining, .functionalStrengthTraining: return .strength
        default: return .other
        }
    }
}

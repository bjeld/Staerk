import Foundation

struct UserSettings: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var displayName: String
    var weightUnit: WeightUnit
    var lengthUnit: LengthUnit
    var theme: ThemeMode
    var weightGoalKg: Double?
    var waistGoalCm: Double?
    var onboardingCompleted: Bool

    init(
        id: String = "settings",
        displayName: String = "",
        weightUnit: WeightUnit = .kilogram,
        lengthUnit: LengthUnit = .centimeter,
        theme: ThemeMode = .system,
        weightGoalKg: Double? = nil,
        waistGoalCm: Double? = nil,
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.weightUnit = weightUnit
        self.lengthUnit = lengthUnit
        self.theme = theme
        self.weightGoalKg = weightGoalKg
        self.waistGoalCm = waistGoalCm
        self.onboardingCompleted = onboardingCompleted
    }

    var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct BodyMeasurement: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var dateKey: String
    var weightKg: Double?
    var waistCm: Double?

    init(
        id: String = StaerkID.make("m"),
        dateKey: String,
        weightKg: Double? = nil,
        waistCm: Double? = nil
    ) {
        self.id = id
        self.dateKey = dateKey
        self.weightKg = weightKg
        self.waistCm = waistCm
    }
}

struct ProgressImage: Identifiable, Hashable, Sendable {
    var id: String
    var dateKey: String
    var createdAt: Date
    var imageData: Data
    var mimeType: String

    init(
        id: String = StaerkID.make("ph"),
        dateKey: String,
        createdAt: Date = Date(),
        imageData: Data,
        mimeType: String = "image/jpeg"
    ) {
        self.id = id
        self.dateKey = dateKey
        self.createdAt = createdAt
        self.imageData = imageData
        self.mimeType = mimeType
    }
}

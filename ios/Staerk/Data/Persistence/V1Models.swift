import Foundation
import SwiftData

/// Original 1.0 SwiftData types. Used only to read the `staerk-martin` store
/// and version-1 backup JSON. Not part of the current schema.
@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var muscleGroupRaw: String
    var workoutRaw: String
    var defaultSets: Int
    var defaultRepsMin: Int
    var defaultRepsMax: Int
    var logTypeRaw: String
    var notes: String
    var order: Int
    var archived: Bool

    init(
        id: String,
        name: String,
        muscleGroupRaw: String,
        workoutRaw: String,
        defaultSets: Int,
        defaultRepsMin: Int,
        defaultRepsMax: Int,
        logTypeRaw: String,
        notes: String,
        order: Int,
        archived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.muscleGroupRaw = muscleGroupRaw
        self.workoutRaw = workoutRaw
        self.defaultSets = defaultSets
        self.defaultRepsMin = defaultRepsMin
        self.defaultRepsMax = defaultRepsMax
        self.logTypeRaw = logTypeRaw
        self.notes = notes
        self.order = order
        self.archived = archived
    }
}

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: String
    var dateKey: String
    var workoutRaw: String
    var completed: Bool
    var startedAt: Date
    var finishedAt: Date?
    var note: String?
    var exercisesBlob: Data

    var exercises: [SessionExerciseBlock] {
        get { (try? JSONDecoder().decode([SessionExerciseBlock].self, from: exercisesBlob)) ?? [] }
        set { exercisesBlob = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(
        id: String,
        dateKey: String,
        workoutRaw: String,
        completed: Bool,
        startedAt: Date,
        finishedAt: Date?,
        note: String?,
        exercisesBlob: Data
    ) {
        self.id = id
        self.dateKey = dateKey
        self.workoutRaw = workoutRaw
        self.completed = completed
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.note = note
        self.exercisesBlob = exercisesBlob
    }
}

@Model
final class DayLog {
    @Attribute(.unique) var dateKey: String
    var creatine: Bool
    var waterGlasses: Int
    var alcoholFree: Bool
    var steps: Int?
    var walkMinutes: Int?
    var golf: Bool

    init(
        dateKey: String,
        creatine: Bool = false,
        waterGlasses: Int = 0,
        alcoholFree: Bool = true,
        steps: Int? = nil,
        walkMinutes: Int? = nil,
        golf: Bool = false
    ) {
        self.dateKey = dateKey
        self.creatine = creatine
        self.waterGlasses = waterGlasses
        self.alcoholFree = alcoholFree
        self.steps = steps
        self.walkMinutes = walkMinutes
        self.golf = golf
    }
}

@Model
final class Measurement {
    @Attribute(.unique) var id: String
    var dateKey: String
    var weightKg: Double?
    var waistCm: Double?

    init(id: String, dateKey: String, weightKg: Double? = nil, waistCm: Double? = nil) {
        self.id = id
        self.dateKey = dateKey
        self.weightKg = weightKg
        self.waistCm = waistCm
    }
}

@Model
final class ProgressPhoto {
    @Attribute(.unique) var id: String
    var dateKey: String
    var createdAt: Date
    var imageData: Data
    var mimeType: String

    init(id: String, dateKey: String, createdAt: Date, imageData: Data, mimeType: String) {
        self.id = id
        self.dateKey = dateKey
        self.createdAt = createdAt
        self.imageData = imageData
        self.mimeType = mimeType
    }
}

@Model
final class AppSettings {
    @Attribute(.unique) var id: String
    var displayName: String
    var waterGoal: Int
    var creatineReminder: Bool
    var reminderTime: String
    var workoutReminder: Bool
    var themeRaw: String
    var weightGoalKg: Double?
    var waistGoalCm: Double?

    init(
        id: String,
        displayName: String,
        waterGoal: Int,
        creatineReminder: Bool,
        reminderTime: String,
        workoutReminder: Bool,
        themeRaw: String,
        weightGoalKg: Double?,
        waistGoalCm: Double?
    ) {
        self.id = id
        self.displayName = displayName
        self.waterGoal = waterGoal
        self.creatineReminder = creatineReminder
        self.reminderTime = reminderTime
        self.workoutReminder = workoutReminder
        self.themeRaw = themeRaw
        self.weightGoalKg = weightGoalKg
        self.waistGoalCm = waistGoalCm
    }
}

enum V1Schema {
    static var models: [any PersistentModel.Type] {
        [
            Exercise.self,
            WorkoutSession.self,
            DayLog.self,
            Measurement.self,
            ProgressPhoto.self,
            AppSettings.self
        ]
    }
}

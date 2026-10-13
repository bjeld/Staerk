import Foundation
import SwiftData

struct SetLog: Codable, Hashable, Identifiable {
    var id: String
    var weight: Double
    var reps: Int
    var done: Bool

    init(id: String = UUID().uuidString, weight: Double, reps: Int, done: Bool) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.done = done
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        if let value = try? container.decode(Double.self, forKey: .weight) {
            weight = value
        } else if let value = try? container.decode(Int.self, forKey: .weight) {
            weight = Double(value)
        } else {
            weight = 0
        }
        if let value = try? container.decode(Int.self, forKey: .reps) {
            reps = value
        } else if let value = try? container.decode(Double.self, forKey: .reps) {
            reps = Int(value.rounded())
        } else {
            reps = 0
        }
        done = try container.decodeIfPresent(Bool.self, forKey: .done) ?? false
    }
}

struct SessionExerciseBlock: Codable, Hashable, Identifiable {
    var exerciseId: String
    var sets: [SetLog]

    var id: String { exerciseId }
}

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

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .legs }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var workout: WorkoutLetter {
        get { WorkoutLetter(rawValue: workoutRaw) ?? .A }
        set { workoutRaw = newValue.rawValue }
    }

    var logType: LogType {
        get { LogType(rawValue: logTypeRaw) ?? .reps }
        set { logTypeRaw = newValue.rawValue }
    }

    var rangeLabel: String {
        if logType == .seconds {
            return "\(defaultSets) × \(defaultRepsMin)–\(defaultRepsMax) sek"
        }
        return "\(muscleGroup.label) · \(defaultSets) × \(defaultRepsMin)–\(defaultRepsMax)"
    }

    init(
        id: String,
        name: String,
        muscleGroup: MuscleGroup,
        workout: WorkoutLetter,
        defaultSets: Int,
        defaultRepsMin: Int,
        defaultRepsMax: Int,
        logType: LogType,
        notes: String,
        order: Int,
        archived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.workoutRaw = workout.rawValue
        self.defaultSets = defaultSets
        self.defaultRepsMin = defaultRepsMin
        self.defaultRepsMax = defaultRepsMax
        self.logTypeRaw = logType.rawValue
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

    var workout: WorkoutLetter {
        get { WorkoutLetter(rawValue: workoutRaw) ?? .A }
        set { workoutRaw = newValue.rawValue }
    }

    var exercises: [SessionExerciseBlock] {
        get {
            (try? JSONDecoder().decode([SessionExerciseBlock].self, from: exercisesBlob)) ?? []
        }
        set {
            exercisesBlob = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var doneSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.done).count }
    }

    init(
        id: String = StaerkID.make("ses"),
        dateKey: String,
        workout: WorkoutLetter,
        completed: Bool,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        note: String? = nil,
        exercises: [SessionExerciseBlock]
    ) {
        self.id = id
        self.dateKey = dateKey
        self.workoutRaw = workout.rawValue
        self.completed = completed
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.note = note
        self.exercisesBlob = (try? JSONEncoder().encode(exercises)) ?? Data()
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

    init(id: String = StaerkID.make("m"), dateKey: String, weightKg: Double? = nil, waistCm: Double? = nil) {
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

    var theme: ThemeMode {
        get { ThemeMode(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue }
    }

    init(
        id: String = "settings",
        displayName: String = "Martin",
        waterGoal: Int = 8,
        creatineReminder: Bool = true,
        reminderTime: String = "06:15",
        workoutReminder: Bool = true,
        theme: ThemeMode = .system,
        weightGoalKg: Double? = nil,
        waistGoalCm: Double? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.waterGoal = waterGoal
        self.creatineReminder = creatineReminder
        self.reminderTime = reminderTime
        self.workoutReminder = workoutReminder
        self.themeRaw = theme.rawValue
        self.weightGoalKg = weightGoalKg
        self.waistGoalCm = waistGoalCm
    }

    static func makeDefault() -> AppSettings {
        AppSettings()
    }
}

import Foundation

struct TrainingProgram: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var name: String
    var notes: String
    var isActive: Bool
    var sortOrder: Int
    var templateID: String?

    init(
        id: String = StaerkID.make("prg"),
        name: String,
        notes: String = "",
        isActive: Bool = true,
        sortOrder: Int = 0,
        templateID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.templateID = templateID
    }
}

struct WorkoutPlan: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var programID: String
    var name: String
    var sortOrder: Int

    init(
        id: String = StaerkID.make("wo"),
        programID: String,
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.programID = programID
        self.name = name
        self.sortOrder = sortOrder
    }
}

struct ExerciseDefinition: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var workoutID: String
    var name: String
    var muscleGroup: MuscleGroup
    var defaultSets: Int
    var defaultRepsMin: Int
    var defaultRepsMax: Int
    var logType: LogType
    var notes: String
    var sortOrder: Int
    var archived: Bool

    init(
        id: String = StaerkID.make("ex"),
        workoutID: String,
        name: String,
        muscleGroup: MuscleGroup,
        defaultSets: Int = 3,
        defaultRepsMin: Int = 8,
        defaultRepsMax: Int = 12,
        logType: LogType = .reps,
        notes: String = "",
        sortOrder: Int = 0,
        archived: Bool = false
    ) {
        self.id = id
        self.workoutID = workoutID
        self.name = name
        self.muscleGroup = muscleGroup
        self.defaultSets = defaultSets
        self.defaultRepsMin = defaultRepsMin
        self.defaultRepsMax = defaultRepsMax
        self.logType = logType
        self.notes = notes
        self.sortOrder = sortOrder
        self.archived = archived
    }
}

struct WeeklySchedule: Hashable, Codable, Sendable {
    /// Index 0 = Monday … 6 = Sunday. `nil` means rest.
    var workoutIDs: [String?]

    init(workoutIDs: [String?] = Array(repeating: nil, count: 7)) {
        var ids = workoutIDs
        if ids.count < 7 {
            ids.append(contentsOf: Array(repeating: nil, count: 7 - ids.count))
        }
        self.workoutIDs = Array(ids.prefix(7))
    }

    func workoutID(on date: Date) -> String? {
        workoutIDs[Dates.weekdayIndex(date)]
    }

    var trainingWeekdays: WeekdaySet {
        var set: WeekdaySet = []
        for (index, id) in workoutIDs.enumerated() where id != nil {
            set.insert(WeekdaySet.ordered[index])
        }
        return set
    }

    var isEmpty: Bool {
        workoutIDs.allSatisfy { $0 == nil }
    }
}

struct SetLog: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var weightKg: Double
    var reps: Int
    var done: Bool

    init(id: String = UUID().uuidString, weightKg: Double, reps: Int, done: Bool) {
        self.id = id
        self.weightKg = weightKg
        self.reps = reps
        self.done = done
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        if let value = try container.decodeIfPresent(Double.self, forKey: .weightKg) {
            weightKg = value
        } else if let value = try? container.decode(Double.self, forKey: .weight) {
            weightKg = value
        } else if let value = try? container.decode(Int.self, forKey: .weight) {
            weightKg = Double(value)
        } else {
            weightKg = 0
        }
        if let value = try container.decodeIfPresent(Int.self, forKey: .reps) {
            reps = value
        } else if let value = try? container.decode(Double.self, forKey: .reps) {
            reps = Int(value.rounded())
        } else {
            reps = 0
        }
        done = try container.decodeIfPresent(Bool.self, forKey: .done) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(weightKg, forKey: .weightKg)
        try container.encode(reps, forKey: .reps)
        try container.encode(done, forKey: .done)
    }

    private enum CodingKeys: String, CodingKey {
        case id, weightKg, weight, reps, done
    }
}

struct SessionExerciseBlock: Codable, Hashable, Identifiable, Sendable {
    var exerciseId: String
    var name: String
    var muscleGroupRaw: String
    var logTypeRaw: String
    var sets: [SetLog]

    var id: String { exerciseId }

    var muscleGroup: MuscleGroup {
        MuscleGroup(rawValue: muscleGroupRaw) ?? .legs
    }

    var logType: LogType {
        LogType(rawValue: logTypeRaw) ?? .reps
    }

    init(
        exerciseId: String,
        name: String = "",
        muscleGroup: MuscleGroup = .legs,
        logType: LogType = .reps,
        sets: [SetLog]
    ) {
        self.exerciseId = exerciseId
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.logTypeRaw = logType.rawValue
        self.sets = sets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exerciseId = try container.decode(String.self, forKey: .exerciseId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        muscleGroupRaw = try container.decodeIfPresent(String.self, forKey: .muscleGroupRaw) ?? MuscleGroup.legs.rawValue
        logTypeRaw = try container.decodeIfPresent(String.self, forKey: .logTypeRaw) ?? LogType.reps.rawValue
        sets = try container.decodeIfPresent([SetLog].self, forKey: .sets) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case exerciseId, name, muscleGroupRaw, logTypeRaw, sets
    }
}

struct SessionLog: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var dateKey: String
    var workoutID: String
    var workoutName: String
    var completed: Bool
    var startedAt: Date
    var finishedAt: Date?
    var note: String?
    var exercises: [SessionExerciseBlock]

    var doneSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.done).count }
    }

    init(
        id: String = StaerkID.make("ses"),
        dateKey: String,
        workoutID: String,
        workoutName: String,
        completed: Bool,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        note: String? = nil,
        exercises: [SessionExerciseBlock]
    ) {
        self.id = id
        self.dateKey = dateKey
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.completed = completed
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.note = note
        self.exercises = exercises
    }
}

struct LastPerformance: Hashable, Sendable {
    var dateKey: String
    var sets: [SetLog]
    var topWeightKg: Double
    var topReps: Int
}

enum ProgressionAdvice: Equatable, Sendable {
    case startReps(min: Int, max: Int)
    case startSeconds(min: Int, max: Int)
    case increaseWeight(fromKg: Double, toKg: Double, repsMax: Int)
    case holdForMaxReps(weightKg: Double, maxReps: Int)
    case stayUntilMin(weightKg: Double, minReps: Int)
    case addSeconds
    case holdSeconds(min: Int, max: Int)
}

struct DayPlan: Equatable, Sendable {
    var date: Date
    var workout: WorkoutPlan?
    var isTrainingDay: Bool { workout != nil }
}

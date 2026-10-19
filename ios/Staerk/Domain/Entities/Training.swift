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

struct CircuitStation: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var name: String
    var sortOrder: Int

    init(
        id: String = StaerkID.make("st"),
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
    }
}

struct WorkoutPlan: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var programID: String
    var name: String
    var sortOrder: Int
    var kind: WorkoutKind
    var location: String
    var stations: [CircuitStation]
    var targetRounds: Int?
    var targetDurationMinutes: Int?

    init(
        id: String = StaerkID.make("wo"),
        programID: String,
        name: String,
        sortOrder: Int = 0,
        kind: WorkoutKind = .detailed,
        location: String = "",
        stations: [CircuitStation] = [],
        targetRounds: Int? = nil,
        targetDurationMinutes: Int? = nil
    ) {
        self.id = id
        self.programID = programID
        self.name = name
        self.sortOrder = sortOrder
        self.kind = kind
        self.location = location
        self.stations = stations.sorted { $0.sortOrder < $1.sortOrder }
        self.targetRounds = targetRounds.flatMap { $0 > 0 ? $0 : nil }
        self.targetDurationMinutes = targetDurationMinutes.flatMap { $0 > 0 ? $0 : nil }
    }

    var isCircuit: Bool { kind.isCircuit }

    var trimmedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        programID = try container.decode(String.self, forKey: .programID)
        name = try container.decode(String.self, forKey: .name)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        kind = try container.decodeIfPresent(WorkoutKind.self, forKey: .kind) ?? .detailed
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        stations = try container.decodeIfPresent([CircuitStation].self, forKey: .stations) ?? []
        targetRounds = try container.decodeIfPresent(Int.self, forKey: .targetRounds)
        targetDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .targetDurationMinutes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(programID, forKey: .programID)
        try container.encode(name, forKey: .name)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(kind, forKey: .kind)
        try container.encode(location, forKey: .location)
        try container.encode(stations, forKey: .stations)
        try container.encodeIfPresent(targetRounds, forKey: .targetRounds)
        try container.encodeIfPresent(targetDurationMinutes, forKey: .targetDurationMinutes)
    }

    private enum CodingKeys: String, CodingKey {
        case id, programID, name, sortOrder, kind, location, stations, targetRounds, targetDurationMinutes
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

    var scheduledDayCount: Int {
        workoutIDs.filter { $0 != nil }.count
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
    var kind: WorkoutKind
    var durationMinutes: Int?
    var rounds: Int?
    var effort: Int?

    var doneSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.done).count }
    }

    var isCircuit: Bool { kind.isCircuit }

    /// Minutes to persist / chart. Prefers the logged duration, then wall-clock elapsed time.
    var resolvedDurationMinutes: Int? {
        if let durationMinutes, durationMinutes > 0 {
            return durationMinutes
        }
        guard let finishedAt else { return nil }
        let minutes = Int((finishedAt.timeIntervalSince(startedAt) / 60).rounded())
        return minutes > 0 ? minutes : nil
    }

    var healthKitEndDate: Date {
        if let minutes = resolvedDurationMinutes {
            return startedAt.addingTimeInterval(TimeInterval(minutes * 60))
        }
        let end = finishedAt ?? Date()
        return end > startedAt ? end : startedAt.addingTimeInterval(60)
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
        exercises: [SessionExerciseBlock],
        kind: WorkoutKind = .detailed,
        durationMinutes: Int? = nil,
        rounds: Int? = nil,
        effort: Int? = nil
    ) {
        self.id = id
        self.dateKey = dateKey
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.completed = completed
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.note = trimmed.isEmpty ? nil : trimmed
        self.exercises = exercises
        self.kind = kind
        self.durationMinutes = durationMinutes.flatMap { $0 > 0 ? $0 : nil }
        self.rounds = rounds.flatMap { $0 > 0 ? $0 : nil }
        self.effort = EffortRating.clamped(effort)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        dateKey = try container.decode(String.self, forKey: .dateKey)
        workoutID = try container.decode(String.self, forKey: .workoutID)
        workoutName = try container.decode(String.self, forKey: .workoutName)
        completed = try container.decode(Bool.self, forKey: .completed)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        finishedAt = try container.decodeIfPresent(Date.self, forKey: .finishedAt)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        exercises = try container.decodeIfPresent([SessionExerciseBlock].self, forKey: .exercises) ?? []
        kind = try container.decodeIfPresent(WorkoutKind.self, forKey: .kind) ?? .detailed
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
        rounds = try container.decodeIfPresent(Int.self, forKey: .rounds)
        effort = EffortRating.clamped(try container.decodeIfPresent(Int.self, forKey: .effort))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dateKey, forKey: .dateKey)
        try container.encode(workoutID, forKey: .workoutID)
        try container.encode(workoutName, forKey: .workoutName)
        try container.encode(completed, forKey: .completed)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(finishedAt, forKey: .finishedAt)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encode(exercises, forKey: .exercises)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        try container.encodeIfPresent(rounds, forKey: .rounds)
        try container.encodeIfPresent(effort, forKey: .effort)
    }

    private enum CodingKeys: String, CodingKey {
        case id, dateKey, workoutID, workoutName, completed, startedAt, finishedAt, note, exercises
        case kind, durationMinutes, rounds, effort
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

/// What Today / Training should show for a given date.
/// Recovery copy is only valid when a live schedule exists.
enum DayTrainingStatus: Equatable, Sendable {
    case unconfigured
    case rest
    case training(WorkoutPlan)

    var workout: WorkoutPlan? {
        if case .training(let workout) = self { return workout }
        return nil
    }

    var isTrainingDay: Bool {
        if case .training = self { return true }
        return false
    }

    var showsStatus: Bool {
        self != .unconfigured
    }
}

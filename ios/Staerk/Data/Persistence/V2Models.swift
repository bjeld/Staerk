import Foundation
import SwiftData

@Model
final class HabitRecord {
    @Attribute(.unique) var id: String
    var name: String
    var kindRaw: String
    var symbol: String
    var tintHex: String
    var weekdaysMask: Int
    var goal: Int
    var reminderEnabled: Bool
    var reminderTime: String
    var sortOrder: Int
    var archived: Bool
    var notes: String
    var templateID: String?

    init(from habit: Habit) {
        id = habit.id
        name = habit.name
        kindRaw = habit.kind.rawValue
        symbol = habit.symbol
        tintHex = habit.tintHex
        weekdaysMask = habit.weekdays.rawValue
        goal = habit.goal
        reminderEnabled = habit.reminderEnabled
        reminderTime = habit.reminderTime
        sortOrder = habit.sortOrder
        archived = habit.archived
        notes = habit.notes
        templateID = habit.templateID
    }

    func apply(_ habit: Habit) {
        name = habit.name
        kindRaw = habit.kind.rawValue
        symbol = habit.symbol
        tintHex = habit.tintHex
        weekdaysMask = habit.weekdays.rawValue
        goal = habit.goal
        reminderEnabled = habit.reminderEnabled
        reminderTime = habit.reminderTime
        sortOrder = habit.sortOrder
        archived = habit.archived
        notes = habit.notes
        templateID = habit.templateID
    }

    func asDomain() -> Habit {
        Habit(
            id: id,
            name: name,
            kind: HabitKind(rawValue: kindRaw) ?? .boolean,
            symbol: symbol,
            tintHex: tintHex,
            weekdays: WeekdaySet(rawValue: weekdaysMask),
            goal: goal,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            sortOrder: sortOrder,
            archived: archived,
            notes: notes,
            templateID: templateID
        )
    }
}

@Model
final class HabitEntryRecord {
    @Attribute(.unique) var id: String
    var habitID: String
    var dateKey: String
    var boolValue: Bool
    var countValue: Int

    init(from entry: HabitEntry) {
        id = entry.id
        habitID = entry.habitID
        dateKey = entry.dateKey
        boolValue = entry.boolValue
        countValue = entry.countValue
    }

    func apply(_ entry: HabitEntry) {
        habitID = entry.habitID
        dateKey = entry.dateKey
        boolValue = entry.boolValue
        countValue = entry.countValue
    }

    func asDomain() -> HabitEntry {
        HabitEntry(id: id, habitID: habitID, dateKey: dateKey, boolValue: boolValue, countValue: countValue)
    }
}

@Model
final class ProgramRecord {
    @Attribute(.unique) var id: String
    var name: String
    var notes: String
    var isActive: Bool
    var sortOrder: Int
    var templateID: String?

    init(from program: TrainingProgram) {
        id = program.id
        name = program.name
        notes = program.notes
        isActive = program.isActive
        sortOrder = program.sortOrder
        templateID = program.templateID
    }

    func apply(_ program: TrainingProgram) {
        name = program.name
        notes = program.notes
        isActive = program.isActive
        sortOrder = program.sortOrder
        templateID = program.templateID
    }

    func asDomain() -> TrainingProgram {
        TrainingProgram(
            id: id,
            name: name,
            notes: notes,
            isActive: isActive,
            sortOrder: sortOrder,
            templateID: templateID
        )
    }
}

@Model
final class WorkoutRecord {
    @Attribute(.unique) var id: String
    var programID: String
    var name: String
    var sortOrder: Int

    init(from workout: WorkoutPlan) {
        id = workout.id
        programID = workout.programID
        name = workout.name
        sortOrder = workout.sortOrder
    }

    func apply(_ workout: WorkoutPlan) {
        programID = workout.programID
        name = workout.name
        sortOrder = workout.sortOrder
    }

    func asDomain() -> WorkoutPlan {
        WorkoutPlan(id: id, programID: programID, name: name, sortOrder: sortOrder)
    }
}

@Model
final class ExerciseRecord {
    @Attribute(.unique) var id: String
    var workoutID: String
    var name: String
    var muscleGroupRaw: String
    var defaultSets: Int
    var defaultRepsMin: Int
    var defaultRepsMax: Int
    var logTypeRaw: String
    var notes: String
    var sortOrder: Int
    var archived: Bool

    init(from exercise: ExerciseDefinition) {
        id = exercise.id
        workoutID = exercise.workoutID
        name = exercise.name
        muscleGroupRaw = exercise.muscleGroup.rawValue
        defaultSets = exercise.defaultSets
        defaultRepsMin = exercise.defaultRepsMin
        defaultRepsMax = exercise.defaultRepsMax
        logTypeRaw = exercise.logType.rawValue
        notes = exercise.notes
        sortOrder = exercise.sortOrder
        archived = exercise.archived
    }

    func apply(_ exercise: ExerciseDefinition) {
        workoutID = exercise.workoutID
        name = exercise.name
        muscleGroupRaw = exercise.muscleGroup.rawValue
        defaultSets = exercise.defaultSets
        defaultRepsMin = exercise.defaultRepsMin
        defaultRepsMax = exercise.defaultRepsMax
        logTypeRaw = exercise.logType.rawValue
        notes = exercise.notes
        sortOrder = exercise.sortOrder
        archived = exercise.archived
    }

    func asDomain() -> ExerciseDefinition {
        ExerciseDefinition(
            id: id,
            workoutID: workoutID,
            name: name,
            muscleGroup: MuscleGroup(rawValue: muscleGroupRaw) ?? .legs,
            defaultSets: defaultSets,
            defaultRepsMin: defaultRepsMin,
            defaultRepsMax: defaultRepsMax,
            logType: LogType(rawValue: logTypeRaw) ?? .reps,
            notes: notes,
            sortOrder: sortOrder,
            archived: archived
        )
    }
}

@Model
final class SessionRecord {
    @Attribute(.unique) var id: String
    var dateKey: String
    var workoutID: String
    var workoutName: String
    var completed: Bool
    var startedAt: Date
    var finishedAt: Date?
    var note: String?
    var exercisesBlob: Data

    var exercises: [SessionExerciseBlock] {
        get { (try? JSONDecoder().decode([SessionExerciseBlock].self, from: exercisesBlob)) ?? [] }
        set { exercisesBlob = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(from session: SessionLog) {
        id = session.id
        dateKey = session.dateKey
        workoutID = session.workoutID
        workoutName = session.workoutName
        completed = session.completed
        startedAt = session.startedAt
        finishedAt = session.finishedAt
        note = session.note
        exercisesBlob = (try? JSONEncoder().encode(session.exercises)) ?? Data()
    }

    func apply(_ session: SessionLog) {
        dateKey = session.dateKey
        workoutID = session.workoutID
        workoutName = session.workoutName
        completed = session.completed
        startedAt = session.startedAt
        finishedAt = session.finishedAt
        note = session.note
        exercises = session.exercises
    }

    func asDomain() -> SessionLog {
        SessionLog(
            id: id,
            dateKey: dateKey,
            workoutID: workoutID,
            workoutName: workoutName,
            completed: completed,
            startedAt: startedAt,
            finishedAt: finishedAt,
            note: note,
            exercises: exercises
        )
    }
}

@Model
final class ScheduleRecord {
    @Attribute(.unique) var id: String
    var workoutIDsBlob: Data

    init(id: String = "schedule", schedule: WeeklySchedule) {
        self.id = id
        workoutIDsBlob = (try? JSONEncoder().encode(schedule.workoutIDs)) ?? Data()
    }

    func apply(_ schedule: WeeklySchedule) {
        workoutIDsBlob = (try? JSONEncoder().encode(schedule.workoutIDs)) ?? Data()
    }

    func asDomain() -> WeeklySchedule {
        let ids = (try? JSONDecoder().decode([String?].self, from: workoutIDsBlob)) ?? Array(repeating: nil, count: 7)
        return WeeklySchedule(workoutIDs: ids)
    }
}

@Model
final class SettingsRecord {
    @Attribute(.unique) var id: String
    var displayName: String
    var weightUnitRaw: String
    var lengthUnitRaw: String
    var themeRaw: String
    var weightGoalKg: Double?
    var waistGoalCm: Double?
    var onboardingCompleted: Bool

    init(from settings: UserSettings) {
        id = settings.id
        displayName = settings.displayName
        weightUnitRaw = settings.weightUnit.rawValue
        lengthUnitRaw = settings.lengthUnit.rawValue
        themeRaw = settings.theme.rawValue
        weightGoalKg = settings.weightGoalKg
        waistGoalCm = settings.waistGoalCm
        onboardingCompleted = settings.onboardingCompleted
    }

    func apply(_ settings: UserSettings) {
        displayName = settings.displayName
        weightUnitRaw = settings.weightUnit.rawValue
        lengthUnitRaw = settings.lengthUnit.rawValue
        themeRaw = settings.theme.rawValue
        weightGoalKg = settings.weightGoalKg
        waistGoalCm = settings.waistGoalCm
        onboardingCompleted = settings.onboardingCompleted
    }

    func asDomain() -> UserSettings {
        UserSettings(
            id: id,
            displayName: displayName,
            weightUnit: WeightUnit(rawValue: weightUnitRaw) ?? .kilogram,
            lengthUnit: LengthUnit(rawValue: lengthUnitRaw) ?? .centimeter,
            theme: ThemeMode(rawValue: themeRaw) ?? .system,
            weightGoalKg: weightGoalKg,
            waistGoalCm: waistGoalCm,
            onboardingCompleted: onboardingCompleted
        )
    }
}

@Model
final class MeasurementRecord {
    @Attribute(.unique) var id: String
    var dateKey: String
    var weightKg: Double?
    var waistCm: Double?

    init(from measurement: BodyMeasurement) {
        id = measurement.id
        dateKey = measurement.dateKey
        weightKg = measurement.weightKg
        waistCm = measurement.waistCm
    }

    func asDomain() -> BodyMeasurement {
        BodyMeasurement(id: id, dateKey: dateKey, weightKg: weightKg, waistCm: waistCm)
    }
}

@Model
final class PhotoRecord {
    @Attribute(.unique) var id: String
    var dateKey: String
    var createdAt: Date
    var imageData: Data
    var mimeType: String

    init(from photo: ProgressImage) {
        id = photo.id
        dateKey = photo.dateKey
        createdAt = photo.createdAt
        imageData = photo.imageData
        mimeType = photo.mimeType
    }

    func asDomain() -> ProgressImage {
        ProgressImage(id: id, dateKey: dateKey, createdAt: createdAt, imageData: imageData, mimeType: mimeType)
    }
}

enum V2Schema {
    static var models: [any PersistentModel.Type] {
        [
            HabitRecord.self,
            HabitEntryRecord.self,
            ProgramRecord.self,
            WorkoutRecord.self,
            ExerciseRecord.self,
            SessionRecord.self,
            ScheduleRecord.self,
            SettingsRecord.self,
            MeasurementRecord.self,
            PhotoRecord.self
        ]
    }

    static var schema: Schema {
        Schema(models)
    }
}

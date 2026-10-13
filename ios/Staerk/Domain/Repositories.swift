import Foundation

@MainActor
protocol HabitRepository {
    func habits(includeArchived: Bool) throws -> [Habit]
    func habit(id: String) throws -> Habit?
    func save(_ habit: Habit) throws
    func delete(id: String) throws
    func entries(from startKey: String, to endKey: String) throws -> [HabitEntry]
    func entries(on dateKey: String) throws -> [HabitEntry]
    func upsert(_ entry: HabitEntry) throws
}

@MainActor
protocol TrainingRepository {
    func programs() throws -> [TrainingProgram]
    func activeProgram() throws -> TrainingProgram?
    func save(_ program: TrainingProgram) throws
    func deleteProgram(id: String) throws
    func setActiveProgram(id: String) throws

    func workouts(programID: String) throws -> [WorkoutPlan]
    func workout(id: String) throws -> WorkoutPlan?
    func save(_ workout: WorkoutPlan) throws
    func deleteWorkout(id: String) throws

    func exercises(workoutID: String, includeArchived: Bool) throws -> [ExerciseDefinition]
    func exercises(includeArchived: Bool) throws -> [ExerciseDefinition]
    func exercise(id: String) throws -> ExerciseDefinition?
    func save(_ exercise: ExerciseDefinition) throws
    func deleteExercise(id: String) throws

    func schedule() throws -> WeeklySchedule
    func save(schedule: WeeklySchedule) throws
}

@MainActor
protocol SessionRepository {
    func sessions() throws -> [SessionLog]
    func session(id: String) throws -> SessionLog?
    func save(_ session: SessionLog) throws
    func delete(id: String) throws
}

@MainActor
protocol SettingsRepository {
    func settings() throws -> UserSettings
    func save(_ settings: UserSettings) throws
}

@MainActor
protocol MeasurementRepository {
    func measurements() throws -> [BodyMeasurement]
    func save(_ measurement: BodyMeasurement) throws
    func delete(id: String) throws
}

@MainActor
protocol PhotoRepository {
    func photos() throws -> [ProgressImage]
    func save(_ photo: ProgressImage) throws
    func delete(id: String) throws
}

@MainActor
protocol BackupRepository {
    func exportJSON() throws -> String
    func importJSON(_ json: String) throws
}

@MainActor
protocol NotificationScheduling {
    func currentStatus() async -> NotificationAuthStatus
    func requestAuthorization() async -> Bool
    func reschedule(habits: [Habit], schedule: WeeklySchedule, workouts: [WorkoutPlan]) async
}

enum NotificationAuthStatus: String, Sendable {
    case notDetermined
    case denied
    case authorized
}

@MainActor
protocol HealthServing: AnyObject {
    var isAvailable: Bool { get }
    var didRequestAuthorization: Bool { get }
    var lastError: String? { get }
    var isRefreshing: Bool { get }
    var today: TodayHealth { get }
    var showsPermissionPrompt: Bool { get }
    var showsDeniedHelp: Bool { get }
    var writeAuthorized: Bool { get }

    func requestAccess() async
    func refreshToday() async
    func saveStrengthWorkout(start: Date, end: Date) async
    func saveBodyMass(kg: Double, at date: Date) async
}

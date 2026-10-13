import Foundation
import SwiftData

@MainActor
final class SwiftDataHabitRepository: HabitRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func habits(includeArchived: Bool) throws -> [Habit] {
        var descriptor = FetchDescriptor<HabitRecord>(sortBy: [SortDescriptor(\.sortOrder)])
        if !includeArchived {
            descriptor.predicate = #Predicate { !$0.archived }
        }
        return try context.fetch(descriptor).map { $0.asDomain() }
    }

    func habit(id: String) throws -> Habit? {
        try record(id: id)?.asDomain()
    }

    func save(_ habit: Habit) throws {
        if let existing = try record(id: habit.id) {
            existing.apply(habit)
        } else {
            context.insert(HabitRecord(from: habit))
        }
        try context.save()
    }

    func delete(id: String) throws {
        if let existing = try record(id: id) {
            context.delete(existing)
        }
        let key = id
        let entries = try context.fetch(FetchDescriptor<HabitEntryRecord>(predicate: #Predicate { $0.habitID == key }))
        for entry in entries {
            context.delete(entry)
        }
        try context.save()
    }

    func entries(from startKey: String, to endKey: String) throws -> [HabitEntry] {
        let start = startKey
        let end = endKey
        let descriptor = FetchDescriptor<HabitEntryRecord>(
            predicate: #Predicate { $0.dateKey >= start && $0.dateKey <= end }
        )
        return try context.fetch(descriptor).map { $0.asDomain() }
    }

    func entries(on dateKey: String) throws -> [HabitEntry] {
        let key = dateKey
        let descriptor = FetchDescriptor<HabitEntryRecord>(predicate: #Predicate { $0.dateKey == key })
        return try context.fetch(descriptor).map { $0.asDomain() }
    }

    func upsert(_ entry: HabitEntry) throws {
        let habitID = entry.habitID
        let dateKey = entry.dateKey
        var descriptor = FetchDescriptor<HabitEntryRecord>(
            predicate: #Predicate { $0.habitID == habitID && $0.dateKey == dateKey }
        )
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(entry)
        } else {
            context.insert(HabitEntryRecord(from: entry))
        }
        try context.save()
    }

    private func record(id: String) throws -> HabitRecord? {
        let key = id
        var descriptor = FetchDescriptor<HabitRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

@MainActor
final class SwiftDataTrainingRepository: TrainingRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func programs() throws -> [TrainingProgram] {
        try context.fetch(FetchDescriptor<ProgramRecord>(sortBy: [SortDescriptor(\.sortOrder)])).map { $0.asDomain() }
    }

    func activeProgram() throws -> TrainingProgram? {
        var descriptor = FetchDescriptor<ProgramRecord>(predicate: #Predicate { $0.isActive })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.asDomain() ?? (try programs().first)
    }

    func save(_ program: TrainingProgram) throws {
        if let existing = try programRecord(id: program.id) {
            existing.apply(program)
        } else {
            context.insert(ProgramRecord(from: program))
        }
        try context.save()
    }

    func deleteProgram(id: String) throws {
        let workouts = try workouts(programID: id)
        for workout in workouts {
            try deleteWorkout(id: workout.id)
        }
        if let existing = try programRecord(id: id) {
            context.delete(existing)
        }
        try context.save()
    }

    func setActiveProgram(id: String) throws {
        let all = try context.fetch(FetchDescriptor<ProgramRecord>())
        for program in all {
            program.isActive = program.id == id
        }
        try context.save()
    }

    func workouts(programID: String) throws -> [WorkoutPlan] {
        let key = programID
        return try context.fetch(
            FetchDescriptor<WorkoutRecord>(
                predicate: #Predicate { $0.programID == key },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
        ).map { $0.asDomain() }
    }

    func workout(id: String) throws -> WorkoutPlan? {
        try workoutRecord(id: id)?.asDomain()
    }

    func save(_ workout: WorkoutPlan) throws {
        if let existing = try workoutRecord(id: workout.id) {
            existing.apply(workout)
        } else {
            context.insert(WorkoutRecord(from: workout))
        }
        try context.save()
    }

    func deleteWorkout(id: String) throws {
        let key = id
        let rows = try context.fetch(FetchDescriptor<ExerciseRecord>(predicate: #Predicate { $0.workoutID == key }))
        for row in rows {
            context.delete(row)
        }
        if let existing = try workoutRecord(id: id) {
            context.delete(existing)
        }
        try context.save()
    }

    func exercises(workoutID: String, includeArchived: Bool) throws -> [ExerciseDefinition] {
        let key = workoutID
        var descriptor = FetchDescriptor<ExerciseRecord>(
            predicate: #Predicate { $0.workoutID == key },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let rows = try context.fetch(descriptor)
        return rows.compactMap { row in
            if !includeArchived && row.archived { return nil }
            return row.asDomain()
        }
    }

    func exercises(includeArchived: Bool) throws -> [ExerciseDefinition] {
        let rows = try context.fetch(FetchDescriptor<ExerciseRecord>(sortBy: [SortDescriptor(\.sortOrder)]))
        return rows.compactMap { row in
            if !includeArchived && row.archived { return nil }
            return row.asDomain()
        }
    }

    func exercise(id: String) throws -> ExerciseDefinition? {
        try exerciseRecord(id: id)?.asDomain()
    }

    func save(_ exercise: ExerciseDefinition) throws {
        if let existing = try exerciseRecord(id: exercise.id) {
            existing.apply(exercise)
        } else {
            context.insert(ExerciseRecord(from: exercise))
        }
        try context.save()
    }

    func deleteExercise(id: String) throws {
        if let existing = try exerciseRecord(id: id) {
            context.delete(existing)
            try context.save()
        }
    }

    func schedule() throws -> WeeklySchedule {
        var descriptor = FetchDescriptor<ScheduleRecord>()
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            return existing.asDomain()
        }
        return WeeklySchedule()
    }

    func save(schedule: WeeklySchedule) throws {
        var descriptor = FetchDescriptor<ScheduleRecord>()
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(schedule)
        } else {
            context.insert(ScheduleRecord(schedule: schedule))
        }
        try context.save()
    }

    private func programRecord(id: String) throws -> ProgramRecord? {
        let key = id
        var descriptor = FetchDescriptor<ProgramRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func workoutRecord(id: String) throws -> WorkoutRecord? {
        let key = id
        var descriptor = FetchDescriptor<WorkoutRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func exerciseRecord(id: String) throws -> ExerciseRecord? {
        let key = id
        var descriptor = FetchDescriptor<ExerciseRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

@MainActor
final class SwiftDataSessionRepository: SessionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func sessions() throws -> [SessionLog] {
        try context.fetch(
            FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.dateKey, order: .reverse)])
        ).map { $0.asDomain() }
    }

    func session(id: String) throws -> SessionLog? {
        let key = id
        var descriptor = FetchDescriptor<SessionRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.asDomain()
    }

    func save(_ session: SessionLog) throws {
        let key = session.id
        var descriptor = FetchDescriptor<SessionRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(session)
        } else {
            context.insert(SessionRecord(from: session))
        }
        try context.save()
    }

    func delete(id: String) throws {
        let key = id
        var descriptor = FetchDescriptor<SessionRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }
}

@MainActor
final class SwiftDataSettingsRepository: SettingsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func settings() throws -> UserSettings {
        var descriptor = FetchDescriptor<SettingsRecord>()
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            return existing.asDomain()
        }
        let created = UserSettings()
        context.insert(SettingsRecord(from: created))
        try context.save()
        return created
    }

    func save(_ settings: UserSettings) throws {
        var descriptor = FetchDescriptor<SettingsRecord>()
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(settings)
        } else {
            context.insert(SettingsRecord(from: settings))
        }
        try context.save()
    }
}

@MainActor
final class SwiftDataMeasurementRepository: MeasurementRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func measurements() throws -> [BodyMeasurement] {
        try context.fetch(
            FetchDescriptor<MeasurementRecord>(sortBy: [SortDescriptor(\.dateKey)])
        ).map { $0.asDomain() }
    }

    func save(_ measurement: BodyMeasurement) throws {
        context.insert(MeasurementRecord(from: measurement))
        try context.save()
    }

    func delete(id: String) throws {
        let key = id
        var descriptor = FetchDescriptor<MeasurementRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }
}

@MainActor
final class SwiftDataPhotoRepository: PhotoRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func photos() throws -> [ProgressImage] {
        try context.fetch(
            FetchDescriptor<PhotoRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        ).map { $0.asDomain() }
    }

    func save(_ photo: ProgressImage) throws {
        context.insert(PhotoRecord(from: photo))
        try context.save()
    }

    func delete(id: String) throws {
        let key = id
        var descriptor = FetchDescriptor<PhotoRecord>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }
}

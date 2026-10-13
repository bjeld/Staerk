import Foundation
import SwiftData

@MainActor
enum StoreBootstrap {
    static let currentStoreName = "staerk"
    static let legacyStoreName = "staerk-martin"
    private static let migratedKey = "staerk.migratedFromV1"

    static func makeContainer() -> ModelContainer {
        let schema = V2Schema.schema
        let configuration = ModelConfiguration(currentStoreName, schema: schema)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            migrateIfNeeded(into: container.mainContext)
            return container
        } catch {
            fatalError("SwiftData could not open: \(error)")
        }
    }

    private static func legacyStoreExists() -> Bool {
        let roots = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let base = roots.first else { return false }
        let names = ["\(legacyStoreName).store", "\(legacyStoreName).sqlite", "default.store"]
        return names.contains { FileManager.default.fileExists(atPath: base.appendingPathComponent($0).path) }
    }

    static func migrateIfNeeded(into context: ModelContext) {
        if UserDefaults.standard.bool(forKey: migratedKey) {
            return
        }
        let settingsCount = (try? context.fetchCount(FetchDescriptor<SettingsRecord>())) ?? 0
        let habitCount = (try? context.fetchCount(FetchDescriptor<HabitRecord>())) ?? 0
        if settingsCount > 0 || habitCount > 0 {
            UserDefaults.standard.set(true, forKey: migratedKey)
            return
        }
        guard let snapshot = loadLegacySnapshot() else { return }
        apply(snapshot: snapshot, into: context)
        UserDefaults.standard.set(true, forKey: migratedKey)
    }

    private static func loadLegacySnapshot() -> LegacySnapshot? {
        guard legacyStoreExists() else { return nil }
        let schema = Schema(V1Schema.models)
        let configuration = ModelConfiguration(legacyStoreName, schema: schema)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = container.mainContext
            let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
            let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
            let days = (try? context.fetch(FetchDescriptor<DayLog>())) ?? []
            let measurements = (try? context.fetch(FetchDescriptor<Measurement>())) ?? []
            let photos = (try? context.fetch(FetchDescriptor<ProgressPhoto>())) ?? []
            let settings = try? context.fetch(FetchDescriptor<AppSettings>()).first
            let hasData = settings != nil
                || !exercises.isEmpty
                || !sessions.isEmpty
                || !days.isEmpty
                || !measurements.isEmpty
                || !photos.isEmpty
            guard hasData else { return nil }
            return LegacySnapshot(
                exercises: exercises.map {
                    LegacyExerciseDTO(
                        id: $0.id,
                        name: $0.name,
                        muscleGroupRaw: $0.muscleGroupRaw,
                        workoutRaw: $0.workoutRaw,
                        defaultSets: $0.defaultSets,
                        defaultRepsMin: $0.defaultRepsMin,
                        defaultRepsMax: $0.defaultRepsMax,
                        logTypeRaw: $0.logTypeRaw,
                        notes: $0.notes,
                        order: $0.order,
                        archived: $0.archived
                    )
                },
                sessions: sessions.map {
                    LegacySessionDTO(
                        id: $0.id,
                        dateKey: $0.dateKey,
                        workoutRaw: $0.workoutRaw,
                        completed: $0.completed,
                        startedAt: $0.startedAt,
                        finishedAt: $0.finishedAt,
                        note: $0.note,
                        exercises: $0.exercises
                    )
                },
                days: days.map {
                    LegacyDayDTO(
                        dateKey: $0.dateKey,
                        creatine: $0.creatine,
                        waterGlasses: $0.waterGlasses,
                        alcoholFree: $0.alcoholFree,
                        golf: $0.golf
                    )
                },
                measurements: measurements.map {
                    BodyMeasurement(id: $0.id, dateKey: $0.dateKey, weightKg: $0.weightKg, waistCm: $0.waistCm)
                },
                photos: photos.map {
                    ProgressImage(
                        id: $0.id,
                        dateKey: $0.dateKey,
                        createdAt: $0.createdAt,
                        imageData: $0.imageData,
                        mimeType: $0.mimeType
                    )
                },
                settings: settings.map {
                    LegacySettingsDTO(
                        displayName: $0.displayName,
                        waterGoal: $0.waterGoal,
                        creatineReminder: $0.creatineReminder,
                        reminderTime: $0.reminderTime,
                        workoutReminder: $0.workoutReminder,
                        themeRaw: $0.themeRaw,
                        weightGoalKg: $0.weightGoalKg,
                        waistGoalCm: $0.waistGoalCm
                    )
                }
            )
        } catch {
            return nil
        }
    }

    static func apply(snapshot: LegacySnapshot, into context: ModelContext) {
        let packed = ProgramCatalog.materialize(ProgramCatalog.martin)
        context.insert(ProgramRecord(from: packed.program))
        for workout in packed.workouts {
            context.insert(WorkoutRecord(from: workout))
        }

        let workoutA = packed.workouts.first
        let workoutB = packed.workouts.dropFirst().first ?? packed.workouts.first
        var exerciseIDMap: [String: String] = [:]

        if snapshot.exercises.isEmpty {
            for exercise in packed.exercises {
                context.insert(ExerciseRecord(from: exercise))
            }
        } else {
            for dto in snapshot.exercises {
                let workoutID = dto.workoutRaw == "B" ? (workoutB?.id ?? "") : (workoutA?.id ?? "")
                let definition = ExerciseDefinition(
                    id: dto.id,
                    workoutID: workoutID,
                    name: dto.name,
                    muscleGroup: MuscleGroup(rawValue: dto.muscleGroupRaw) ?? .legs,
                    defaultSets: dto.defaultSets,
                    defaultRepsMin: dto.defaultRepsMin,
                    defaultRepsMax: dto.defaultRepsMax,
                    logType: LogType(rawValue: dto.logTypeRaw) ?? .reps,
                    notes: dto.notes,
                    sortOrder: dto.order,
                    archived: dto.archived
                )
                exerciseIDMap[dto.id] = dto.id
                context.insert(ExerciseRecord(from: definition))
            }
        }

        context.insert(ScheduleRecord(schedule: packed.schedule))

        let settingsDTO = snapshot.settings
        let reminder = settingsDTO?.reminderTime ?? "06:15"
        var water = HabitCatalog.make(HabitCatalog.water, sortOrder: 1)
        water.goal = max(1, settingsDTO?.waterGoal ?? 8)
        water.reminderEnabled = false
        var creatine = HabitCatalog.make(HabitCatalog.creatine, sortOrder: 0)
        creatine.reminderEnabled = settingsDTO?.creatineReminder ?? true
        creatine.reminderTime = reminder
        let alcohol = HabitCatalog.make(HabitCatalog.alcoholFree, sortOrder: 2)
        var workoutHabit = HabitCatalog.make(HabitCatalog.workout, sortOrder: 3)
        workoutHabit.reminderEnabled = settingsDTO?.workoutReminder ?? true
        workoutHabit.reminderTime = reminder
        workoutHabit.weekdays = packed.schedule.trainingWeekdays
        let golf = HabitCatalog.make(HabitCatalog.golf, sortOrder: 4)

        let habits = [creatine, water, alcohol, workoutHabit, golf]
        for habit in habits {
            context.insert(HabitRecord(from: habit))
        }

        for day in snapshot.days {
            insertEntry(habitID: creatine.id, dateKey: day.dateKey, boolValue: day.creatine, count: 0, into: context)
            insertEntry(habitID: water.id, dateKey: day.dateKey, boolValue: false, count: day.waterGlasses, into: context)
            insertEntry(habitID: alcohol.id, dateKey: day.dateKey, boolValue: day.alcoholFree, count: 0, into: context)
            if day.golf {
                insertEntry(habitID: golf.id, dateKey: day.dateKey, boolValue: true, count: 0, into: context)
            }
        }

        let exerciseLookup = Dictionary(uniqueKeysWithValues: snapshot.exercises.map { ($0.id, $0) })
        for session in snapshot.sessions {
            let workout = session.workoutRaw == "B" ? workoutB : workoutA
            let blocks = session.exercises.map { block -> SessionExerciseBlock in
                let source = exerciseLookup[block.exerciseId]
                return SessionExerciseBlock(
                    exerciseId: exerciseIDMap[block.exerciseId] ?? block.exerciseId,
                    name: source?.name ?? block.name,
                    muscleGroup: MuscleGroup(rawValue: source?.muscleGroupRaw ?? block.muscleGroupRaw) ?? .legs,
                    logType: LogType(rawValue: source?.logTypeRaw ?? block.logTypeRaw) ?? .reps,
                    sets: block.sets
                )
            }
            let log = SessionLog(
                id: session.id,
                dateKey: session.dateKey,
                workoutID: workout?.id ?? session.workoutRaw,
                workoutName: workout?.name ?? session.workoutRaw,
                completed: session.completed,
                startedAt: session.startedAt,
                finishedAt: session.finishedAt,
                note: session.note,
                exercises: blocks
            )
            context.insert(SessionRecord(from: log))
            if session.completed {
                insertEntry(habitID: workoutHabit.id, dateKey: session.dateKey, boolValue: true, count: 0, into: context)
            }
        }

        for measurement in snapshot.measurements {
            context.insert(MeasurementRecord(from: measurement))
        }
        for photo in snapshot.photos {
            context.insert(PhotoRecord(from: photo))
        }

        let user = UserSettings(
            displayName: settingsDTO?.displayName ?? "",
            weightUnit: .kilogram,
            lengthUnit: .centimeter,
            theme: ThemeMode(rawValue: settingsDTO?.themeRaw ?? "") ?? .system,
            weightGoalKg: settingsDTO?.weightGoalKg,
            waistGoalCm: settingsDTO?.waistGoalCm,
            onboardingCompleted: true
        )
        context.insert(SettingsRecord(from: user))
        try? context.save()
    }

    private static func insertEntry(
        habitID: String,
        dateKey: String,
        boolValue: Bool,
        count: Int,
        into context: ModelContext
    ) {
        guard boolValue || count > 0 else { return }
        let entry = HabitEntry(habitID: habitID, dateKey: dateKey, boolValue: boolValue, countValue: count)
        context.insert(HabitEntryRecord(from: entry))
    }
}

struct LegacySnapshot {
    var exercises: [LegacyExerciseDTO]
    var sessions: [LegacySessionDTO]
    var days: [LegacyDayDTO]
    var measurements: [BodyMeasurement]
    var photos: [ProgressImage]
    var settings: LegacySettingsDTO?
}

struct LegacyExerciseDTO {
    var id: String
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
}

struct LegacySessionDTO {
    var id: String
    var dateKey: String
    var workoutRaw: String
    var completed: Bool
    var startedAt: Date
    var finishedAt: Date?
    var note: String?
    var exercises: [SessionExerciseBlock]
}

struct LegacyDayDTO {
    var dateKey: String
    var creatine: Bool
    var waterGlasses: Int
    var alcoholFree: Bool
    var golf: Bool
}

struct LegacySettingsDTO {
    var displayName: String
    var waterGoal: Int
    var creatineReminder: Bool
    var reminderTime: String
    var workoutReminder: Bool
    var themeRaw: String
    var weightGoalKg: Double?
    var waistGoalCm: Double?
}

enum DataSeeder {
    @MainActor
    static func applyOnboarding(
        name: String,
        weightUnit: WeightUnit,
        lengthUnit: LengthUnit,
        habits: [Habit],
        blueprint: ProgramBlueprint?,
        context: ModelContext
    ) throws {
        wipeConfiguration(in: context)

        let settings = UserSettings(
            displayName: name,
            weightUnit: weightUnit,
            lengthUnit: lengthUnit,
            onboardingCompleted: true
        )
        context.insert(SettingsRecord(from: settings))

        for habit in habits {
            context.insert(HabitRecord(from: habit))
        }

        if let blueprint {
            let packed = ProgramCatalog.materialize(blueprint)
            context.insert(ProgramRecord(from: packed.program))
            for workout in packed.workouts {
                context.insert(WorkoutRecord(from: workout))
            }
            for exercise in packed.exercises {
                context.insert(ExerciseRecord(from: exercise))
            }
            context.insert(ScheduleRecord(schedule: packed.schedule))
        }

        try context.save()
    }

    @MainActor
    static func wipeConfiguration(in context: ModelContext) {
        func wipe<T: PersistentModel>(_ type: T.Type) {
            let rows = (try? context.fetch(FetchDescriptor<T>())) ?? []
            for row in rows { context.delete(row) }
        }
        wipe(HabitRecord.self)
        wipe(HabitEntryRecord.self)
        wipe(ProgramRecord.self)
        wipe(WorkoutRecord.self)
        wipe(ExerciseRecord.self)
        wipe(ScheduleRecord.self)
        wipe(SettingsRecord.self)
    }
}

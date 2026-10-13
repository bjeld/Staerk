import Foundation
import SwiftData
import UniformTypeIdentifiers
import SwiftUI

struct BackupPayloadV2: Codable {
    var version: Int
    var exportedAt: String
    var habits: [Habit]
    var entries: [HabitEntry]
    var programs: [TrainingProgram]
    var workouts: [WorkoutPlan]
    var exercises: [ExerciseDefinition]
    var sessions: [SessionLog]
    var schedule: WeeklySchedule
    var settings: UserSettings?
    var measurements: [BodyMeasurement]
    var photos: [PhotoDTO]
}

struct PhotoDTO: Codable {
    var id: String
    var date: String
    var createdAt: Double
    var mimeType: String
    var dataUrl: String
}

struct BackupPayloadV1: Codable {
    var version: Int
    var exportedAt: String
    var exercises: [ExerciseDTOV1]
    var sessions: [SessionDTOV1]
    var days: [DayDTOV1]
    var measurements: [MeasurementDTOV1]
    var settings: SettingsDTOV1?
    var photos: [PhotoDTO]
}

struct ExerciseDTOV1: Codable {
    var id: String
    var name: String
    var muscleGroup: String
    var workout: String
    var defaultSets: Int
    var defaultRepsMin: Int
    var defaultRepsMax: Int
    var logType: String
    var notes: String
    var order: Int
    var archived: Bool
}

struct SessionDTOV1: Codable {
    var id: String
    var date: String
    var workout: String
    var completed: Bool
    var exercises: [SessionExerciseBlock]
    var startedAt: Double
    var finishedAt: Double?
    var note: String?
}

struct DayDTOV1: Codable {
    var date: String
    var creatine: Bool
    var waterGlasses: Int
    var alcoholFree: Bool
    var steps: Int?
    var walkMinutes: Int?
    var golf: Bool
}

struct MeasurementDTOV1: Codable {
    var id: String
    var date: String
    var weightKg: Double?
    var waistCm: Double?
}

struct SettingsDTOV1: Codable {
    var id: String?
    var displayName: String
    var waterGoal: Int
    var creatineReminder: Bool
    var reminderTime: String
    var workoutReminder: Bool
    var theme: String
    var weightGoalKg: Double?
    var waistGoalCm: Double?
}

enum BackupError: LocalizedError {
    case encoding
    case unknownFormat

    var errorDescription: String? {
        switch self {
        case .encoding: return String(localized: "backup.error.encoding")
        case .unknownFormat: return String(localized: "backup.error.format")
        }
    }
}

@MainActor
final class SwiftDataBackupRepository: BackupRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func exportJSON() throws -> String {
        let habits = (try? context.fetch(FetchDescriptor<HabitRecord>())) ?? []
        let entries = (try? context.fetch(FetchDescriptor<HabitEntryRecord>())) ?? []
        let programs = (try? context.fetch(FetchDescriptor<ProgramRecord>())) ?? []
        let workouts = (try? context.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
        let exercises = (try? context.fetch(FetchDescriptor<ExerciseRecord>())) ?? []
        let sessions = (try? context.fetch(FetchDescriptor<SessionRecord>())) ?? []
        let schedule = (try? context.fetch(FetchDescriptor<ScheduleRecord>()))?.first
        let settings = (try? context.fetch(FetchDescriptor<SettingsRecord>()))?.first
        let measurements = (try? context.fetch(FetchDescriptor<MeasurementRecord>())) ?? []
        let photos = (try? context.fetch(FetchDescriptor<PhotoRecord>())) ?? []

        let payload = BackupPayloadV2(
            version: 2,
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            habits: habits.map { $0.asDomain() },
            entries: entries.map { $0.asDomain() },
            programs: programs.map { $0.asDomain() },
            workouts: workouts.map { $0.asDomain() },
            exercises: exercises.map { $0.asDomain() },
            sessions: sessions.map { $0.asDomain() },
            schedule: schedule?.asDomain() ?? WeeklySchedule(),
            settings: settings?.asDomain(),
            measurements: measurements.map { $0.asDomain() },
            photos: photos.map {
                PhotoDTO(
                    id: $0.id,
                    date: $0.dateKey,
                    createdAt: $0.createdAt.timeIntervalSince1970 * 1000,
                    mimeType: $0.mimeType,
                    dataUrl: "data:\($0.mimeType);base64,\($0.imageData.base64EncodedString())"
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        guard let json = String(data: data, encoding: .utf8) else { throw BackupError.encoding }
        return json
    }

    func importJSON(_ json: String) throws {
        guard let data = json.data(using: .utf8) else { throw BackupError.encoding }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let payload = try? decoder.decode(BackupPayloadV2.self, from: data), payload.version == 2 {
            try importV2(payload)
            return
        }
        if let payload = try? decoder.decode(BackupPayloadV1.self, from: data), payload.version == 1 {
            try importV1(payload)
            return
        }
        throw BackupError.unknownFormat
    }

    private func importV2(_ payload: BackupPayloadV2) throws {
        wipeAll()
        for habit in payload.habits { context.insert(HabitRecord(from: habit)) }
        for entry in payload.entries { context.insert(HabitEntryRecord(from: entry)) }
        for program in payload.programs { context.insert(ProgramRecord(from: program)) }
        for workout in payload.workouts { context.insert(WorkoutRecord(from: workout)) }
        for exercise in payload.exercises { context.insert(ExerciseRecord(from: exercise)) }
        for session in payload.sessions { context.insert(SessionRecord(from: session)) }
        context.insert(ScheduleRecord(schedule: payload.schedule))
        if let settings = payload.settings {
            context.insert(SettingsRecord(from: settings))
        } else {
            context.insert(SettingsRecord(from: UserSettings(onboardingCompleted: true)))
        }
        for measurement in payload.measurements { context.insert(MeasurementRecord(from: measurement)) }
        for dto in payload.photos {
            let imageData = Self.dataFromDataURL(dto.dataUrl) ?? Data()
            context.insert(
                PhotoRecord(
                    from: ProgressImage(
                        id: dto.id,
                        dateKey: dto.date,
                        createdAt: Date(timeIntervalSince1970: dto.createdAt / 1000),
                        imageData: imageData,
                        mimeType: dto.mimeType.isEmpty ? "image/jpeg" : dto.mimeType
                    )
                )
            )
        }
        try context.save()
    }

    private func importV1(_ payload: BackupPayloadV1) throws {
        wipeAll()
        let snapshot = LegacySnapshot(
            exercises: payload.exercises.map {
                LegacyExerciseDTO(
                    id: $0.id,
                    name: $0.name,
                    muscleGroupRaw: $0.muscleGroup,
                    workoutRaw: $0.workout,
                    defaultSets: $0.defaultSets,
                    defaultRepsMin: $0.defaultRepsMin,
                    defaultRepsMax: $0.defaultRepsMax,
                    logTypeRaw: $0.logType,
                    notes: $0.notes,
                    order: $0.order,
                    archived: $0.archived
                )
            },
            sessions: payload.sessions.map {
                LegacySessionDTO(
                    id: $0.id,
                    dateKey: $0.date,
                    workoutRaw: $0.workout,
                    completed: $0.completed,
                    startedAt: Date(timeIntervalSince1970: $0.startedAt / 1000),
                    finishedAt: $0.finishedAt.map { Date(timeIntervalSince1970: $0 / 1000) },
                    note: $0.note,
                    exercises: $0.exercises
                )
            },
            days: payload.days.map {
                LegacyDayDTO(
                    dateKey: $0.date,
                    creatine: $0.creatine,
                    waterGlasses: $0.waterGlasses,
                    alcoholFree: $0.alcoholFree,
                    golf: $0.golf
                )
            },
            measurements: payload.measurements.map {
                BodyMeasurement(id: $0.id, dateKey: $0.date, weightKg: $0.weightKg, waistCm: $0.waistCm)
            },
            photos: payload.photos.map {
                ProgressImage(
                    id: $0.id,
                    dateKey: $0.date,
                    createdAt: Date(timeIntervalSince1970: $0.createdAt / 1000),
                    imageData: Self.dataFromDataURL($0.dataUrl) ?? Data(),
                    mimeType: $0.mimeType
                )
            },
            settings: payload.settings.map {
                LegacySettingsDTO(
                    displayName: $0.displayName,
                    waterGoal: $0.waterGoal,
                    creatineReminder: $0.creatineReminder,
                    reminderTime: $0.reminderTime,
                    workoutReminder: $0.workoutReminder,
                    themeRaw: $0.theme,
                    weightGoalKg: $0.weightGoalKg,
                    waistGoalCm: $0.waistGoalCm
                )
            }
        )
        StoreBootstrap.apply(snapshot: snapshot, into: context)
    }

    private func wipeAll() {
        func wipe<T: PersistentModel>(_ type: T.Type) {
            let rows = (try? context.fetch(FetchDescriptor<T>())) ?? []
            for row in rows { context.delete(row) }
        }
        wipe(HabitRecord.self)
        wipe(HabitEntryRecord.self)
        wipe(ProgramRecord.self)
        wipe(WorkoutRecord.self)
        wipe(ExerciseRecord.self)
        wipe(SessionRecord.self)
        wipe(ScheduleRecord.self)
        wipe(SettingsRecord.self)
        wipe(MeasurementRecord.self)
        wipe(PhotoRecord.self)
    }

    private static func dataFromDataURL(_ url: String) -> Data? {
        if let range = url.range(of: "base64,") {
            return Data(base64Encoded: String(url[range.upperBound...]))
        }
        return Data(base64Encoded: url)
    }
}

struct JSONFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8)
        else { throw BackupError.encoding }
        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

import Foundation
import SwiftData
import UniformTypeIdentifiers
import SwiftUI

struct BackupPayload: Codable {
    var version: Int
    var exportedAt: String
    var exercises: [ExerciseDTO]
    var sessions: [SessionDTO]
    var days: [DayDTO]
    var measurements: [MeasurementDTO]
    var settings: SettingsDTO?
    var photos: [PhotoDTO]
}

struct ExerciseDTO: Codable {
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

struct SessionDTO: Codable {
    var id: String
    var date: String
    var workout: String
    var completed: Bool
    var exercises: [SessionExerciseBlock]
    var startedAt: Double
    var finishedAt: Double?
    var note: String?
}

struct DayDTO: Codable {
    var date: String
    var creatine: Bool
    var waterGlasses: Int
    var alcoholFree: Bool
    var steps: Int?
    var walkMinutes: Int?
    var golf: Bool
}

struct MeasurementDTO: Codable {
    var id: String
    var date: String
    var weightKg: Double?
    var waistCm: Double?
}

struct SettingsDTO: Codable {
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

struct PhotoDTO: Codable {
    var id: String
    var date: String
    var createdAt: Double
    var mimeType: String
    var dataUrl: String
}

enum BackupService {
    static func exportJSON(from context: ModelContext) throws -> String {
        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let days = (try? context.fetch(FetchDescriptor<DayLog>())) ?? []
        let measurements = (try? context.fetch(FetchDescriptor<Measurement>())) ?? []
        let settings = (try? context.fetch(FetchDescriptor<AppSettings>()))?.first
        let photos = (try? context.fetch(FetchDescriptor<ProgressPhoto>())) ?? []

        let payload = BackupPayload(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            exercises: exercises.map {
                ExerciseDTO(
                    id: $0.id,
                    name: $0.name,
                    muscleGroup: $0.muscleGroupRaw,
                    workout: $0.workoutRaw,
                    defaultSets: $0.defaultSets,
                    defaultRepsMin: $0.defaultRepsMin,
                    defaultRepsMax: $0.defaultRepsMax,
                    logType: $0.logTypeRaw,
                    notes: $0.notes,
                    order: $0.order,
                    archived: $0.archived
                )
            },
            sessions: sessions.map {
                SessionDTO(
                    id: $0.id,
                    date: $0.dateKey,
                    workout: $0.workoutRaw,
                    completed: $0.completed,
                    exercises: $0.exercises,
                    startedAt: $0.startedAt.timeIntervalSince1970 * 1000,
                    finishedAt: $0.finishedAt.map { $0.timeIntervalSince1970 * 1000 },
                    note: $0.note
                )
            },
            days: days.map {
                DayDTO(
                    date: $0.dateKey,
                    creatine: $0.creatine,
                    waterGlasses: $0.waterGlasses,
                    alcoholFree: $0.alcoholFree,
                    steps: $0.steps,
                    walkMinutes: $0.walkMinutes,
                    golf: $0.golf
                )
            },
            measurements: measurements.map {
                MeasurementDTO(id: $0.id, date: $0.dateKey, weightKg: $0.weightKg, waistCm: $0.waistCm)
            },
            settings: settings.map {
                SettingsDTO(
                    id: $0.id,
                    displayName: $0.displayName,
                    waterGoal: $0.waterGoal,
                    creatineReminder: $0.creatineReminder,
                    reminderTime: $0.reminderTime,
                    workoutReminder: $0.workoutReminder,
                    theme: $0.themeRaw,
                    weightGoalKg: $0.weightGoalKg,
                    waistGoalCm: $0.waistGoalCm
                )
            },
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
        let data = try encoder.encode(payload)
        guard let json = String(data: data, encoding: .utf8) else {
            throw BackupError.encoding
        }
        return json
    }

    static func importJSON(_ json: String, into context: ModelContext) throws {
        guard let data = json.data(using: .utf8) else { throw BackupError.encoding }
        let payload = try JSONDecoder().decode(BackupPayload.self, from: data)
        guard payload.version == 1 else { throw BackupError.unknownFormat }

        func wipe<T: PersistentModel>(_ type: T.Type) {
            let rows = (try? context.fetch(FetchDescriptor<T>())) ?? []
            for row in rows {
                context.delete(row)
            }
        }

        wipe(Exercise.self)
        wipe(WorkoutSession.self)
        wipe(DayLog.self)
        wipe(Measurement.self)
        wipe(ProgressPhoto.self)
        wipe(AppSettings.self)

        for dto in payload.exercises {
            context.insert(
                Exercise(
                    id: dto.id,
                    name: dto.name,
                    muscleGroup: MuscleGroup(rawValue: dto.muscleGroup) ?? .legs,
                    workout: WorkoutLetter(rawValue: dto.workout) ?? .A,
                    defaultSets: dto.defaultSets,
                    defaultRepsMin: dto.defaultRepsMin,
                    defaultRepsMax: dto.defaultRepsMax,
                    logType: LogType(rawValue: dto.logType) ?? .reps,
                    notes: dto.notes,
                    order: dto.order,
                    archived: dto.archived
                )
            )
        }

        for dto in payload.sessions {
            context.insert(
                WorkoutSession(
                    id: dto.id,
                    dateKey: dto.date,
                    workout: WorkoutLetter(rawValue: dto.workout) ?? .A,
                    completed: dto.completed,
                    startedAt: Date(timeIntervalSince1970: dto.startedAt / 1000),
                    finishedAt: dto.finishedAt.map { Date(timeIntervalSince1970: $0 / 1000) },
                    note: dto.note,
                    exercises: dto.exercises
                )
            )
        }

        for dto in payload.days {
            context.insert(
                DayLog(
                    dateKey: dto.date,
                    creatine: dto.creatine,
                    waterGlasses: dto.waterGlasses,
                    alcoholFree: dto.alcoholFree,
                    steps: dto.steps,
                    walkMinutes: dto.walkMinutes,
                    golf: dto.golf
                )
            )
        }

        for dto in payload.measurements {
            context.insert(Measurement(id: dto.id, dateKey: dto.date, weightKg: dto.weightKg, waistCm: dto.waistCm))
        }

        if let dto = payload.settings {
            context.insert(
                AppSettings(
                    id: "settings",
                    displayName: dto.displayName,
                    waterGoal: max(1, dto.waterGoal),
                    creatineReminder: dto.creatineReminder,
                    reminderTime: dto.reminderTime,
                    workoutReminder: dto.workoutReminder,
                    theme: ThemeMode(rawValue: dto.theme) ?? .system,
                    weightGoalKg: dto.weightGoalKg,
                    waistGoalCm: dto.waistGoalCm
                )
            )
        } else {
            context.insert(AppSettings.makeDefault())
        }

        for dto in payload.photos {
            let imageData = Self.dataFromDataURL(dto.dataUrl) ?? Data()
            context.insert(
                ProgressPhoto(
                    id: dto.id,
                    dateKey: dto.date,
                    createdAt: Date(timeIntervalSince1970: dto.createdAt / 1000),
                    imageData: imageData,
                    mimeType: dto.mimeType.isEmpty ? "image/jpeg" : dto.mimeType
                )
            )
        }

        try context.save()
    }

    private static func dataFromDataURL(_ url: String) -> Data? {
        if let range = url.range(of: "base64,") {
            return Data(base64Encoded: String(url[range.upperBound...]))
        }
        return Data(base64Encoded: url)
    }
}

enum BackupError: LocalizedError {
    case encoding
    case unknownFormat

    var errorDescription: String? {
        switch self {
        case .encoding: return "Filen kunne ikke læses. Tjek at det er en STÆRK-backup."
        case .unknownFormat: return "Ukendt backup-format"
        }
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
        else {
            throw BackupError.encoding
        }
        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

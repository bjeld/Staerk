import Foundation
import SwiftData

enum StaerkStore {
    static func settings(in context: ModelContext) -> AppSettings {
        var descriptor = FetchDescriptor<AppSettings>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = AppSettings.makeDefault()
        context.insert(created)
        try? context.save()
        return created
    }

    static func day(for dateKey: String, in context: ModelContext) -> DayLog {
        let key = dateKey
        var descriptor = FetchDescriptor<DayLog>(predicate: #Predicate { $0.dateKey == key })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = DayLog(dateKey: key)
        context.insert(created)
        try? context.save()
        return created
    }

    static func exercise(id: String, in context: ModelContext) -> Exercise? {
        let key = id
        var descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    static func session(id: String, in context: ModelContext) -> WorkoutSession? {
        let key = id
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == key })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}

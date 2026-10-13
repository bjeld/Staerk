import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AppContainer {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let habits: HabitRepository
    let training: TrainingRepository
    let sessions: SessionRepository
    let settings: SettingsRepository
    let measurements: MeasurementRepository
    let photos: PhotoRepository
    let backup: BackupRepository
    let notifications: NotificationScheduling
    let health: HealthKitService

    init(container: ModelContainer, health: HealthKitService = HealthKitService()) {
        modelContainer = container
        modelContext = container.mainContext
        habits = SwiftDataHabitRepository(context: container.mainContext)
        training = SwiftDataTrainingRepository(context: container.mainContext)
        sessions = SwiftDataSessionRepository(context: container.mainContext)
        settings = SwiftDataSettingsRepository(context: container.mainContext)
        measurements = SwiftDataMeasurementRepository(context: container.mainContext)
        photos = SwiftDataPhotoRepository(context: container.mainContext)
        backup = SwiftDataBackupRepository(context: container.mainContext)
        notifications = NotificationScheduler()
        self.health = health
    }

    func refreshReminders() async {
        let habitList = (try? habits.habits(includeArchived: false)) ?? []
        let schedule = (try? training.schedule()) ?? WeeklySchedule()
        let program = try? training.activeProgram()
        let workouts = (try? training.workouts(programID: program?.id ?? "")) ?? []
        await notifications.reschedule(habits: habitList, schedule: schedule, workouts: workouts)
    }
}

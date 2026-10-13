import Foundation
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}

@MainActor
final class NotificationScheduler: NotificationScheduling {
    private let prefix = "staerk.habit."

    func currentStatus() async -> NotificationAuthStatus {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        switch status {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        default: return .notDetermined
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func reschedule(habits: [Habit], schedule _: WeeklySchedule, workouts _: [WorkoutPlan]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        let status = await currentStatus()
        guard status == .authorized else { return }

        for habit in habits where habit.reminderEnabled && !habit.archived {
            let time = Dates.reminderComponents(habit.reminderTime)
            let days = habit.weekdays.mondayFirstIndices
            let mapped = days.map { index -> Int in
                // iOS DateComponents.weekday: Sunday=1 … Saturday=7
                // Our index: Monday=0 … Sunday=6 → weekday = ((index + 1) % 7) + 1
                return ((index + 1) % 7) + 1
            }
            let weekdaysToUse: [Int?] = mapped.isEmpty ? [nil] : mapped.map { Optional($0) }

            for weekday in weekdaysToUse {
                let content = UNMutableNotificationContent()
                content.title = habit.name
                content.body = reminderBody(for: habit)
                content.sound = .default
                var comps = time
                comps.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let suffix = weekday.map(String.init) ?? "daily"
                let identifier = "\(prefix)\(habit.id).\(suffix)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    private func reminderBody(for habit: Habit) -> String {
        switch habit.kind {
        case .boolean:
            return String(localized: "notify.boolean.body")
        case .counter:
            return String(format: String(localized: "notify.counter.body"), locale: .current, habit.goal)
        case .workout:
            return String(localized: "notify.workout.body")
        }
    }
}

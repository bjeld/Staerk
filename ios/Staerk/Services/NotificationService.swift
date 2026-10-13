import Foundation
import UserNotifications
import UIKit

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

enum NotificationService {
    private static let creatineID = "staerk-creatine"
    private static let workoutIDs = [
        ("staerk-workout-mon", 2),
        ("staerk-workout-wed", 4),
        ("staerk-workout-fri", 6),
    ]

    static func currentStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func reschedule(settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        var ids = [creatineID]
        ids.append(contentsOf: workoutIDs.map(\.0))
        center.removePendingNotificationRequests(withIdentifiers: ids)

        let status = await currentStatus()
        guard status == .authorized || status == .provisional else { return }

        let time = Dates.reminderComponents(settings.reminderTime)

        if settings.creatineReminder {
            let content = UNMutableNotificationContent()
            content.title = "Kreatin"
            content.body = "Har du taget din kreatin i dag?"
            content.sound = .default
            var comps = time
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: creatineID, content: content, trigger: trigger)
            try? await center.add(request)
        }

        if settings.workoutReminder {
            for (identifier, weekday) in workoutIDs {
                let content = UNMutableNotificationContent()
                content.title = "Træning"
                content.body = "Styrkepas i morges? Log sætene, mens de er i frisk erindring."
                content.sound = .default
                var comps = time
                comps.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }
}

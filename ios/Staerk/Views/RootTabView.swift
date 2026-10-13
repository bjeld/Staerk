import SwiftData
import SwiftUI

struct RootTabView: View {
    @Query private var settingsRows: [AppSettings]
    @Environment(HealthKitService.self) private var health

    private var settings: AppSettings? { settingsRows.first }

    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("I dag", systemImage: "house.fill")
            }

            NavigationStack {
                TrainingView()
            }
            .tabItem {
                Label("Træning", systemImage: "dumbbell.fill")
            }

            NavigationStack {
                HabitsView()
            }
            .tabItem {
                Label("Vaner", systemImage: "flame.fill")
            }

            NavigationStack {
                BodyProgressView()
            }
            .tabItem {
                Label("Krop", systemImage: "figure.stand")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Mere", systemImage: "ellipsis")
            }
        }
        .tint(Palette.accent)
        .preferredColorScheme(settings?.theme.preferredColorScheme)
        .staerkScreen()
        .task {
            if health.didRequestAuthorization {
                await health.refreshToday()
            }
            if let settings {
                await NotificationService.reschedule(settings: settings)
            }
        }
        .onChange(of: settings?.themeRaw) { _, _ in }
        .onChange(of: settings?.reminderTime) { _, _ in
            if let settings {
                Task { await NotificationService.reschedule(settings: settings) }
            }
        }
        .onChange(of: settings?.creatineReminder) { _, _ in
            if let settings {
                Task { await NotificationService.reschedule(settings: settings) }
            }
        }
        .onChange(of: settings?.workoutReminder) { _, _ in
            if let settings {
                Task { await NotificationService.reschedule(settings: settings) }
            }
        }
    }
}

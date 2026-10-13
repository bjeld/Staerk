import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppContainer.self) private var app
    @Query private var settingsRows: [SettingsRecord]

    private var settings: UserSettings {
        settingsRows.first?.asDomain() ?? (try? app.settings.settings()) ?? UserSettings()
    }

    var body: some View {
        Group {
            if settings.onboardingCompleted {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Palette.volt)
        .preferredColorScheme(settings.theme.preferredColorScheme)
        .staerkScreen()
        .staerkKeyboardDone()
        .task {
            if app.health.didRequestAuthorization {
                await app.health.refreshToday()
            }
            if settings.onboardingCompleted {
                await app.refreshReminders()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label(L10n.string("tab.today"), systemImage: "bolt.fill")
            }

            NavigationStack {
                TrainingView()
            }
            .tabItem {
                Label(L10n.string("tab.training"), systemImage: "dumbbell.fill")
            }

            NavigationStack {
                HabitsView()
            }
            .tabItem {
                Label(L10n.string("tab.habits"), systemImage: "flame.fill")
            }

            NavigationStack {
                BodyProgressView()
            }
            .tabItem {
                Label(L10n.string("tab.body"), systemImage: "figure.stand")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(L10n.string("tab.more"), systemImage: "ellipsis")
            }
        }
    }
}

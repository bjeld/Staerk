import SwiftData
import SwiftUI

@main
struct StaerkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var health = HealthKitService()
    private let container: ModelContainer

    init() {
        let schema = Schema([
            Exercise.self,
            WorkoutSession.self,
            DayLog.self,
            Measurement.self,
            ProgressPhoto.self,
            AppSettings.self,
        ])
        let configuration = ModelConfiguration("staerk-martin", schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            Seed.ensure(in: container.mainContext)
        } catch {
            fatalError("SwiftData kunne ikke åbnes: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(health)
                .modelContainer(container)
        }
    }
}

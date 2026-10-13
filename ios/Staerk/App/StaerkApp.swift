import SwiftData
import SwiftUI

@main
struct StaerkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container: AppContainer

    init() {
        let model = StoreBootstrap.makeContainer()
        container = AppContainer(container: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(container.health)
                .modelContainer(container.modelContainer)
        }
    }
}

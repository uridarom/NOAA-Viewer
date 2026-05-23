import SwiftUI

@main
struct SPCOutlookApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        URLCache.shared = URLCache(
            memoryCapacity:  50 * 1024 * 1024,
            diskCapacity:   200 * 1024 * 1024
        )
        BackgroundRefreshManager.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                BackgroundRefreshManager.schedule()
            }
        }
    }
}

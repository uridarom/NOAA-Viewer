import SwiftUI

@main
struct SPCOutlookApp: App {
    init() {
        URLCache.shared = URLCache(
            memoryCapacity:  50 * 1024 * 1024,
            diskCapacity:   200 * 1024 * 1024
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

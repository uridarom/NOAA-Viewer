import BackgroundTasks
import Foundation

enum BackgroundRefreshManager {
    static let taskIdentifier = "com.uridarom.SPCOutlook.refresh"

    // MARK: - Registration

    /// Must be called before the app finishes launching (i.e., in App.init).
    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleRefresh(refreshTask)
        }
    }

    // MARK: - Scheduling

    /// Submits a request to wake the app near the next Day 1 SPC issuance time.
    /// Safe to call repeatedly — BGTaskScheduler replaces any existing pending
    /// request for the same identifier.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = IssuanceSchedule.nextIssuance(for: .one)
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Handler

    private static func handleRefresh(_ task: BGAppRefreshTask) {
        // Re-schedule before doing work so the next slot is always queued.
        schedule()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            await performRefresh()
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Refresh logic

    private static func performRefresh() async {
        let service = SPCNetworkService()

        guard let url = SPCEndpoints.categoricalImage(day: .one)
                     ?? SPCEndpoints.probabilisticImage(day: .one, risk: .general) else { return }

        let serverDate = await service.lastModified(at: url)
        let lastSeen   = PersistenceStore.loadLastUpdatedAt()
        let isNewer    = serverDate.map { $0 > (lastSeen ?? .distantPast) } ?? true

        guard isNewer else { return }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                if let img = try? await service.fetchImage(
                    from: url,
                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
                ) {
                    PersistenceStore.saveCategoricalImage(img, day: .one)
                }
            }
            group.addTask {
                if let text = try? await service.fetchDiscussion(
                    day: .one,
                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
                ) {
                    PersistenceStore.save(discussion: DiscussionParser.parse(text))
                }
            }
        }

        if let date = serverDate {
            PersistenceStore.save(lastUpdatedAt: date)
        }
    }
}

import UIKit

@MainActor
final class OutlookViewModel: ObservableObject {
    @Published var outlookImage: UIImage?
    @Published var thumbnails: [OutlookDay: UIImage] = [:]
    @Published var discussion: ParsedDiscussion?
    @Published var isLoading    = false
    @Published var isRefreshing = false
    @Published var toastMessage: String? = nil

    private let service = SPCNetworkService()
    private var lastSeenIssuanceAt: Date? = nil

    // MARK: - Initial load

    func load(day: OutlookDay, risk: RiskType, bypassCache: Bool = false) async {
        guard let url = imageURL(for: day, risk: risk) else { return }
        isLoading = true
        defer { isLoading = false }
        let policy: URLRequest.CachePolicy = bypassCache ? .reloadIgnoringLocalAndRemoteCacheData
                                                         : .returnCacheDataElseLoad
        do {
            outlookImage = try await service.fetchImage(from: url, cachePolicy: policy)
        } catch {
            // image stays nil; error UI wired in Step 16
        }
    }

    func loadDiscussion(day: OutlookDay, bypassCache: Bool = false) async {
        let policy: URLRequest.CachePolicy = bypassCache ? .reloadIgnoringLocalAndRemoteCacheData
                                                         : .returnCacheDataElseLoad
        do {
            let text = try await service.fetchDiscussion(day: day, cachePolicy: policy)
            discussion = DiscussionParser.parse(text)
        } catch {
            // discussion stays nil; error UI wired in Step 16
        }
    }

    // MARK: - Manual refresh

    func refresh(day: OutlookDay, risk: RiskType) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        // HEAD check: has the server's content changed since the last time we fetched?
        var serverDate: Date? = nil
        if let checkURL = imageURL(for: day, risk: risk) {
            serverDate = await service.lastModified(at: checkURL)
        }

        let isNewer = serverDate.map { $0 > (lastSeenIssuanceAt ?? .distantPast) } ?? true

        guard isNewer else {
            showToast("No new outlook yet")
            return
        }

        // Fresh fetch, bypassing URLCache
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.load(day: day, risk: risk, bypassCache: true) }
            group.addTask { await self.loadDiscussion(day: day, bypassCache: true) }
        }
        lastSeenIssuanceAt = serverDate ?? Date()
        showToast("Updated")
    }

    // MARK: - Thumbnails

    func loadThumbnails() async {
        await withTaskGroup(of: (OutlookDay, UIImage?).self) { group in
            let service = self.service
            for day in OutlookDay.allCases where self.thumbnails[day] == nil {
                group.addTask {
                    guard let url = SPCEndpoints.categoricalImage(day: day)
                            ?? SPCEndpoints.probabilisticImage(day: day, risk: .general) else {
                        return (day, nil)
                    }
                    return (day, try? await service.fetchImage(from: url))
                }
            }
            for await (day, image) in group {
                if let image { thumbnails[day] = image }
            }
        }
    }

    // MARK: - Header strings

    var lastUpdatedString: String {
        guard let date = discussion?.issuance else { return "—" }
        return Self.timeFormatter.string(from: date)
    }

    func nextIssuanceString(for day: OutlookDay) -> String {
        Self.timeFormatter.string(from: IssuanceSchedule.nextIssuance(for: day))
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "h:mm a"
        return f
    }()

    // MARK: - URL resolution

    func imageURL(for day: OutlookDay, risk: RiskType) -> URL? {
        if risk == .general {
            return SPCEndpoints.categoricalImage(day: day)
                ?? SPCEndpoints.probabilisticImage(day: day, risk: .general)
        }
        return SPCEndpoints.probabilisticImage(day: day, risk: risk)
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            toastMessage = nil
        }
    }
}

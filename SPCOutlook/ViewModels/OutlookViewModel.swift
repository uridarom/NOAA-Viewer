import CoreLocation
import SwiftUI

@MainActor
final class OutlookViewModel: ObservableObject {
    @Published var selectedDay: OutlookDay
    @Published var selectedRisk: RiskType
    @Published var outlookImage: UIImage?
    @Published var thumbnails: [OutlookDay: UIImage] = [:]
    @Published var discussion: ParsedDiscussion?
    @Published var isLoading    = false
    @Published var isRefreshing = false
    @Published var toastMessage: String? = nil
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var wfo: String?
    @Published var localRisks: LocalRisks
    @Published var isLocalView: Bool = false
    @Published var localViewDisabled: Bool = false
    /// Set to true once backgroundSync() completes (success or failure), so the UI
    /// can switch from a loading spinner to a "no data" empty state.
    @Published var isInitialLoadComplete: Bool = false
    /// True when the user has denied or restricted location access.
    @Published var locationPermissionDenied: Bool = false

    private let service          = SPCNetworkService()
    private let locationService  = LocationService()
    private var lastSeenIssuanceAt: Date?

    // MARK: - Init (hydrates from file cache before any network call)

    init() {
        let day  = PersistenceStore.loadSelectedDay()  ?? .one
        let risk = PersistenceStore.loadSelectedRisk() ?? .general
        _selectedDay  = Published(initialValue: day)
        _selectedRisk = Published(initialValue: risk)
        _localRisks   = Published(initialValue: PersistenceStore.loadLocalRisks() ?? .zero)
        _discussion   = Published(initialValue: PersistenceStore.loadDiscussion())
        _outlookImage = Published(initialValue: PersistenceStore.loadCategoricalImage(day: day))
        lastSeenIssuanceAt = PersistenceStore.loadLastUpdatedAt()
    }

    // MARK: - Background Sync

    func backgroundSync() async {
        defer { isInitialLoadComplete = true }

        guard let checkURL = imageURL(for: selectedDay, risk: .general) else { return }
        let serverDate = await service.lastModified(at: checkURL)

        // Offline with existing cached data — keep the cache.
        if serverDate == nil, lastSeenIssuanceAt != nil { return }

        let isNewer = serverDate.map { $0 > (lastSeenIssuanceAt ?? .distantPast) } ?? true
        let cacheIncomplete = outlookImage == nil || discussion == nil

        guard isNewer || cacheIncomplete else { return }

        await withTaskGroup(of: Void.self) { group in
            if isNewer || outlookImage == nil {
                group.addTask {
                    await self.load(day: self.selectedDay, risk: self.selectedRisk,
                                    bypassCache: isNewer)
                }
            }
            if isNewer || discussion == nil {
                group.addTask {
                    await self.loadDiscussion(day: self.selectedDay, bypassCache: isNewer)
                }
            }
            if isNewer, self.selectedDay == .one {
                group.addTask { await self.loadLocalRisks() }
            }
        }

        if let date = serverDate, isNewer {
            lastSeenIssuanceAt = date
            PersistenceStore.save(lastUpdatedAt: date)
        }
    }

    // MARK: - Image load

    func load(day: OutlookDay, risk: RiskType, bypassCache: Bool = false) async {
        guard let url = currentImageURL(day: day, risk: risk) else { return }
        isLoading = true
        defer { isLoading = false }
        let policy: URLRequest.CachePolicy = bypassCache ? .reloadIgnoringLocalAndRemoteCacheData
                                                         : .returnCacheDataElseLoad
        do {
            let image = try await service.fetchImage(from: url, cachePolicy: policy)
            outlookImage = image
            if risk == .general, !isLocalView {
                PersistenceStore.saveCategoricalImage(image, day: day)
            }
        } catch {
            if isLocalView {
                isLocalView = false
                localViewDisabled = true
                showToast("Regional outlook not available for your area.")
                if let nationalURL = imageURL(for: day, risk: risk) {
                    if let image = try? await service.fetchImage(from: nationalURL, cachePolicy: policy) {
                        outlookImage = image
                    }
                }
            }
            // else: network error — image stays nil or cached; empty state shown by ContentView
        }
    }

    // MARK: - Local View Toggle

    func toggleLocalView(day: OutlookDay, risk: RiskType) async {
        guard !localViewDisabled, wfo != nil else { return }
        isLocalView.toggle()
        await load(day: day, risk: risk)
    }

    // MARK: - Discussion

    func loadDiscussion(day: OutlookDay, bypassCache: Bool = false) async {
        let policy: URLRequest.CachePolicy = bypassCache ? .reloadIgnoringLocalAndRemoteCacheData
                                                         : .returnCacheDataElseLoad
        do {
            let text = try await service.fetchDiscussion(day: day, cachePolicy: policy)
            let parsed = DiscussionParser.parse(text)
            discussion = parsed
            PersistenceStore.save(discussion: parsed)
        } catch {
            // discussion stays cached; empty state shown by ContentView when nil
        }
    }

    // MARK: - Location & WFO

    func startLocationServices() async {
        guard let coord = await locationService.requestLocation() else {
            // Update denied flag — drives the "Enable location" hint in LocalRisksCard
            let status = locationService.authorizationStatus
            locationPermissionDenied = (status == .denied || status == .restricted)
            return
        }
        locationPermissionDenied = false
        userCoordinate = coord
        async let wfoFetch   = WFOResolver.resolve(coordinate: coord)
        async let risksFetch = computeRisks(at: coord)
        let (resolvedWFO, risks) = await (wfoFetch, risksFetch)
        wfo = resolvedWFO
        if let risks {
            localRisks = risks
            PersistenceStore.save(localRisks: risks)
        }
    }

    // MARK: - Local Risks

    func loadLocalRisks() async {
        guard let coord = userCoordinate else { return }
        if let risks = await computeRisks(at: coord) {
            localRisks = risks
            PersistenceStore.save(localRisks: risks)
        }
    }

    // Returns nil when ALL three GeoJSON fetches fail (e.g. fully offline),
    // so we don't overwrite a previously-cached valid value with all-dashes.
    // When at least one succeeds, individual nil fields signal per-hazard failures.
    private func computeRisks(at coord: CLLocationCoordinate2D) async -> LocalRisks? {
        async let tornado = fetchGeoJSONSafe(day: .one, risk: .tornado)
        async let hail    = fetchGeoJSONSafe(day: .one, risk: .hail)
        async let wind    = fetchGeoJSONSafe(day: .one, risk: .wind)
        let (t, h, w) = await (tornado, hail, wind)
        guard t != nil || h != nil || w != nil else { return nil }
        return LocalRiskCalculator.localRisks(at: coord, tornado: t, hail: h, wind: w)
    }

    private func fetchGeoJSONSafe(day: OutlookDay, risk: RiskType) async -> GeoJSONFeatureCollection? {
        guard let url = SPCEndpoints.geoJSON(day: day, risk: risk) else { return nil }
        return try? await service.fetchGeoJSON(from: url)
    }

    // MARK: - Manual refresh

    func refresh(day: OutlookDay, risk: RiskType) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        var serverDate: Date? = nil
        if let checkURL = imageURL(for: day, risk: risk) {
            serverDate = await service.lastModified(at: checkURL)
        }

        let isNewer = serverDate.map { $0 > (lastSeenIssuanceAt ?? .distantPast) } ?? true

        guard isNewer else {
            showToast("No new outlook yet")
            return
        }

        let imageWasNilBefore = outlookImage == nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.load(day: day, risk: risk, bypassCache: true) }
            group.addTask { await self.loadDiscussion(day: day, bypassCache: true) }
            if day == .one { group.addTask { await self.loadLocalRisks() } }
        }

        // If image was nil before AND is still nil after, the network is unreachable.
        if imageWasNilBefore, outlookImage == nil {
            showToast("No connection — try again later")
            return
        }

        if let date = serverDate {
            lastSeenIssuanceAt = date
            PersistenceStore.save(lastUpdatedAt: date)
        } else {
            lastSeenIssuanceAt = Date()
        }
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

    func currentImageURL(day: OutlookDay, risk: RiskType) -> URL? {
        if isLocalView, let wfo {
            return SPCEndpoints.regionalImage(day: day, risk: risk, wfo: wfo)
                ?? imageURL(for: day, risk: risk)
        }
        return imageURL(for: day, risk: risk)
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

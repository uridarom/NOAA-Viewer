import CoreLocation
import Foundation

enum WFOResolver {
    private static let userAgent = "SPCOutlookApp/1.0 (contact@example.com)"

    // UserDefaults keys
    private static let wfoKey       = "cached_wfo_code"
    private static let wfoLatKey    = "cached_wfo_lat"
    private static let wfoLonKey    = "cached_wfo_lon"

    private static let reResolveTresholdMeters: Double = 50_000

    /// Returns the 3-letter WFO code for `coordinate`, using a UserDefaults cache.
    /// Returns nil on failure (network error, missing cwa, non-CONUS office).
    static func resolve(coordinate: CLLocationCoordinate2D) async -> String? {
        if let cached = cachedWFO(near: coordinate) { return cached }
        guard let fetched = await fetchWFO(coordinate: coordinate) else { return nil }
        cache(wfo: fetched, at: coordinate)
        return fetched
    }

    // MARK: - Private

    private static func fetchWFO(coordinate: CLLocationCoordinate2D) async -> String? {
        let lat = String(format: "%.4f", coordinate.latitude)
        let lon = String(format: "%.4f", coordinate.longitude)
        guard let url = URL(string: "https://api.weather.gov/points/\(lat),\(lon)") else { return nil }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .returnCacheDataElseLoad

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let properties = json["properties"] as? [String: Any],
              let cwa = properties["cwa"] as? String,
              !cwa.isEmpty else { return nil }

        return cwa
    }

    private static func cachedWFO(near coordinate: CLLocationCoordinate2D) -> String? {
        let defaults = UserDefaults.standard
        guard let wfo = defaults.string(forKey: wfoKey) else { return nil }
        let cachedLat = defaults.double(forKey: wfoLatKey)
        let cachedLon = defaults.double(forKey: wfoLonKey)
        let cached = CLLocation(latitude: cachedLat, longitude: cachedLon)
        let current = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard current.distance(from: cached) < reResolveTresholdMeters else { return nil }
        return wfo
    }

    private static func cache(wfo: String, at coordinate: CLLocationCoordinate2D) {
        let defaults = UserDefaults.standard
        defaults.set(wfo, forKey: wfoKey)
        defaults.set(coordinate.latitude,  forKey: wfoLatKey)
        defaults.set(coordinate.longitude, forKey: wfoLonKey)
    }
}

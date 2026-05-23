import UIKit

enum NetworkError: Error {
    case badResponse(Int)
    case invalidImageData
}

struct SPCNetworkService {

    // MARK: - Image

    func fetchImage(from url: URL,
                    cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad) async throws -> UIImage {
        let data = try await fetchData(from: url, cachePolicy: cachePolicy)
        guard let image = UIImage(data: data) else { throw NetworkError.invalidImageData }
        return image
    }

    // MARK: - Discussion text

    func fetchDiscussion(day: OutlookDay,
                         cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad) async throws -> String {
        let data = try await fetchData(from: SPCEndpoints.discussionText(day: day), cachePolicy: cachePolicy)
        guard let text = String(data: data, encoding: .utf8)
                      ?? String(data: data, encoding: .isoLatin1) else {
            throw NetworkError.badResponse(-1)
        }
        return text
    }

    // MARK: - GeoJSON

    func fetchGeoJSON(from url: URL,
                      cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad) async throws -> GeoJSONFeatureCollection {
        let data = try await fetchData(from: url, cachePolicy: cachePolicy)
        return try JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data)
    }

    // MARK: - HEAD check

    /// Issues a HEAD request and returns the server's `Last-Modified` date, or nil if unavailable.
    func lastModified(at url: URL) async -> Date? {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        guard let (_, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse,
              let raw  = http.value(forHTTPHeaderField: "Last-Modified") else { return nil }
        return Self.httpDateFormatter.date(from: raw)
    }

    private static let httpDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "GMT")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return f
    }()

    // MARK: - Raw data

    func fetchData(from url: URL,
                   cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad) async throws -> Data {
        let request = URLRequest(url: url, cachePolicy: cachePolicy)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.badResponse(code)
        }
        return data
    }
}

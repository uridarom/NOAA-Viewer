import Foundation
import UIKit

enum PersistenceStore {
    private static let defaults = UserDefaults.standard
    private static let encoder  = JSONEncoder()
    private static let decoder  = JSONDecoder()

    private enum Key {
        static let selectedDay   = "ps_selectedDay"
        static let selectedRisk  = "ps_selectedRisk"
        static let lastUpdatedAt = "ps_lastUpdatedAt"
        static let localRisks    = "ps_localRisks"
        static let discussion    = "ps_discussion"
    }

    private static var spcCacheDir: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("spc", isDirectory: true)
    }

    // MARK: - Save

    static func save(selectedDay: OutlookDay, selectedRisk: RiskType) {
        defaults.set(selectedDay.rawValue, forKey: Key.selectedDay)
        defaults.set(selectedRisk.rawValue, forKey: Key.selectedRisk)
    }

    static func save(lastUpdatedAt date: Date) {
        defaults.set(date.timeIntervalSinceReferenceDate, forKey: Key.lastUpdatedAt)
    }

    static func save(localRisks: LocalRisks) {
        defaults.set(try? encoder.encode(localRisks), forKey: Key.localRisks)
    }

    static func save(discussion: ParsedDiscussion) {
        defaults.set(try? encoder.encode(discussion), forKey: Key.discussion)
    }

    static func saveCategoricalImage(_ image: UIImage, day: OutlookDay) {
        guard let data = image.pngData() else { return }
        let dir = spcCacheDir
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("day\(day.rawValue)_categorical.png")
        try? data.write(to: file, options: .atomic)
    }

    // MARK: - Load

    static func loadSelectedDay() -> OutlookDay? {
        guard defaults.object(forKey: Key.selectedDay) != nil else { return nil }
        return OutlookDay(rawValue: defaults.integer(forKey: Key.selectedDay))
    }

    static func loadSelectedRisk() -> RiskType? {
        guard let raw = defaults.string(forKey: Key.selectedRisk) else { return nil }
        return RiskType(rawValue: raw)
    }

    static func loadLastUpdatedAt() -> Date? {
        let interval = defaults.double(forKey: Key.lastUpdatedAt)
        return interval > 0 ? Date(timeIntervalSinceReferenceDate: interval) : nil
    }

    static func loadLocalRisks() -> LocalRisks? {
        guard let data = defaults.data(forKey: Key.localRisks) else { return nil }
        return try? decoder.decode(LocalRisks.self, from: data)
    }

    static func loadDiscussion() -> ParsedDiscussion? {
        guard let data = defaults.data(forKey: Key.discussion) else { return nil }
        return try? decoder.decode(ParsedDiscussion.self, from: data)
    }

    static func loadCategoricalImage(day: OutlookDay) -> UIImage? {
        let file = spcCacheDir.appendingPathComponent("day\(day.rawValue)_categorical.png")
        guard let data = try? Data(contentsOf: file) else { return nil }
        return UIImage(data: data)
    }
}

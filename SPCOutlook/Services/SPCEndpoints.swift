import Foundation

enum SPCEndpoints {
    private static let outlookBase = "https://www.spc.noaa.gov/products/outlook/"
    private static let experBase   = "https://www.spc.noaa.gov/products/exper/day4-8/"

    // MARK: - Categorical images (Days 1–3 only; Days 4–8 return nil)

    static func categoricalImage(day: OutlookDay) -> URL? {
        switch day {
        case .one:   return url(outlookBase + "day1otlk.png")
        case .two:   return url(outlookBase + "day2otlk.png")
        case .three: return url(outlookBase + "day3otlk.png")
        default:     return nil
        }
    }

    // MARK: - Probabilistic images
    // Day 1/2: tornado/hail/wind; general returns nil (use categoricalImage instead).
    // Day 3: general returns combined day3prob.png; individual risks return nil.
    // Days 4–8: general returns per-day image from exper path; individual risks return nil.

    static func probabilisticImage(day: OutlookDay, risk: RiskType) -> URL? {
        switch day {
        case .one:
            switch risk {
            case .tornado: return url(outlookBase + "day1probotlk_torn.png")
            case .hail:    return url(outlookBase + "day1probotlk_hail.png")
            case .wind:    return url(outlookBase + "day1probotlk_wind.png")
            case .general: return nil
            }
        case .two:
            switch risk {
            case .tornado: return url(outlookBase + "day2probotlk_torn.png")
            case .hail:    return url(outlookBase + "day2probotlk_hail.png")
            case .wind:    return url(outlookBase + "day2probotlk_wind.png")
            case .general: return nil
            }
        case .three:
            return risk == .general ? url(outlookBase + "day3prob.png") : nil
        default:
            return risk == .general ? url(experBase + "day\(day.rawValue)prob.gif") : nil
        }
    }

    // MARK: - GeoJSON polygon layers
    // Days 1–2: all four risk types.
    // Day 3: general (categorical) only; individual risks return nil.
    // Days 4–8: nil (no per-risk GeoJSON for the combined product).

    static func geoJSON(day: OutlookDay, risk: RiskType) -> URL? {
        switch day {
        case .one:
            return url(outlookBase + "day1otlk_\(geoSuffix(risk)).lyr.geojson")
        case .two:
            return url(outlookBase + "day2otlk_\(geoSuffix(risk)).lyr.geojson")
        case .three:
            return risk == .general ? url(outlookBase + "day3otlk_cat.lyr.geojson") : nil
        default:
            return nil
        }
    }

    // MARK: - Discussion text
    // Days 1–3 have individual files. Days 4–8 share day48otlk.txt under the exper path.

    static func discussionText(day: OutlookDay) -> URL {
        switch day {
        case .one:   return url(outlookBase + "day1otlk.txt")!
        case .two:   return url(outlookBase + "day2otlk.txt")!
        case .three: return url(outlookBase + "day3otlk.txt")!
        default:     return url(experBase + "day48otlk.txt")!
        }
    }

    // MARK: - Regional (WFO) images (§1.5)
    // Days 1–2: categorical + tornado/hail/wind.
    // Day 3: categorical only; individual prob types return nil.
    // Days 4–8: per-day PROB image for .general only; individual risks return nil.

    static func regionalImage(day: OutlookDay, risk: RiskType, wfo: String) -> URL? {
        guard !wfo.isEmpty else { return nil }
        let base = "https://www.spc.noaa.gov/partners/outlooks/cwa/images/"
        let n = day.rawValue
        switch day {
        case .one, .two:
            switch risk {
            case .general:  return url(base + "\(wfo)_swody\(n).png")
            case .tornado:  return url(base + "\(wfo)_swody\(n)_TORN.png")
            case .hail:     return url(base + "\(wfo)_swody\(n)_HAIL.png")
            case .wind:     return url(base + "\(wfo)_swody\(n)_WIND.png")
            }
        case .three:
            return risk == .general ? url(base + "\(wfo)_swody3.png") : nil
        default:
            // Days 4–8: per-day regional PROB images (unlike national which is combined).
            return risk == .general ? url(base + "\(wfo)_swody\(n)_PROB.png") : nil
        }
    }

    // MARK: - Helpers

    private static func url(_ string: String) -> URL? {
        URL(string: string)
    }

    private static func geoSuffix(_ risk: RiskType) -> String {
        switch risk {
        case .general: return "cat"
        case .tornado: return "torn"
        case .hail:    return "hail"
        case .wind:    return "wind"
        }
    }
}

import Foundation

// MARK: - WPC Excessive Rainfall Outlook

struct WPCFeatureCollection: Decodable {
    let features: [WPCFeature]

    private enum CodingKeys: String, CodingKey { case features }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Guard against a null features array (no ERO issued).
        features = (try? c.decode([WPCFeature].self, forKey: .features)) ?? []
    }
}

struct WPCFeature: Decodable {
    let geometry: GeoJSONGeometry?
    let properties: WPCEROProperties

    private enum CodingKeys: String, CodingKey { case geometry, properties }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Null or unsupported geometry types are silently skipped during PIP.
        geometry = try? c.decode(GeoJSONGeometry.self, forKey: .geometry)
        properties = try c.decode(WPCEROProperties.self, forKey: .properties)
    }
}

/// Decodes WPC ERO risk level from ArcGIS MapServer (hazards/wpc_precip_hazards) properties.
/// The service exposes `outlook` (e.g. "Marginal (At Least 5%)") and `dn` (1–4 ordinal).
struct WPCEROProperties: Decodable {
    let probability: Int   // percentage mapped from the category
    let rank: Int          // ordinal for finding the highest-risk polygon

    private enum PropertyKey: String, CodingKey {
        case outlook, dn
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: PropertyKey.self)

        if let outlook = try? c.decode(String.self, forKey: .outlook) {
            (probability, rank) = WPCEROProperties.fromOutlook(outlook)
            return
        }

        let dn = (try? c.decode(Int.self, forKey: .dn)) ?? 0
        (probability, rank) = WPCEROProperties.fromDN(dn)
    }

    private static func fromOutlook(_ s: String) -> (Int, Int) {
        let lower = s.lowercased()
        if lower.contains("marginal") { return (5,  1) }
        if lower.contains("slight")   { return (15, 2) }
        if lower.contains("moderate") { return (30, 3) }
        if lower.contains("high")     { return (60, 4) }
        return (0, 0)
    }

    private static func fromDN(_ dn: Int) -> (Int, Int) {
        switch dn {
        case 1: return (5,  1)
        case 2: return (15, 2)
        case 3: return (30, 3)
        case 4: return (60, 4)
        default: return (0, 0)
        }
    }
}

// MARK: - SPC Outlook

struct GeoJSONFeatureCollection: Decodable {
    let features: [GeoJSONFeature]
}

struct GeoJSONFeature: Decodable {
    let geometry: GeoJSONGeometry
    let properties: OutlookFeatureProperties
}

struct OutlookFeatureProperties: Decodable {
    let dn: Int
    let label: String

    enum CodingKeys: String, CodingKey {
        case dn = "DN"
        case label = "LABEL"
    }
}

enum GeoJSONGeometry: Decodable {
    typealias Ring    = [[Double]]    // array of [lon, lat] pairs
    typealias Polygon = [Ring]        // first ring = exterior, rest = holes

    case polygon(Polygon)
    case multiPolygon([Polygon])

    private enum CodingKeys: String, CodingKey { case type, coordinates }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "Polygon":
            self = .polygon(try c.decode(Polygon.self, forKey: .coordinates))
        case "MultiPolygon":
            self = .multiPolygon(try c.decode([Polygon].self, forKey: .coordinates))
        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Unsupported geometry type: \(type)"))
        }
    }

    var polygons: [Polygon] {
        switch self {
        case .polygon(let p):      return [p]
        case .multiPolygon(let m): return m
        }
    }
}

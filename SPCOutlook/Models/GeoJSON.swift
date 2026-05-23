import Foundation

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

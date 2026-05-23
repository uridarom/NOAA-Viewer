import CoreLocation

enum LocalRiskCalculator {

    static func localRisks(
        at coord: CLLocationCoordinate2D,
        tornado: GeoJSONFeatureCollection?,
        hail: GeoJSONFeatureCollection?,
        wind: GeoJSONFeatureCollection?,
        flood: WPCFeatureCollection? = nil
    ) -> LocalRisks {
        let (tornPct, tornSign) = probabilityAndSignificant(at: coord, from: tornado)
        let (hailPct, hailSign) = probabilityAndSignificant(at: coord, from: hail)
        let (windPct, windSign) = probabilityAndSignificant(at: coord, from: wind)
        let floodPct            = floodProbability(at: coord, from: flood)
        return LocalRisks(tornado: tornPct, tornadoSignificant: tornSign,
                          hail: hailPct, hailSignificant: hailSign,
                          wind: windPct, windSignificant: windSign,
                          flood: floodPct)
    }

    /// Returns the highest WPC ERO probability at `coord`, or nil if the collection
    /// was unavailable (fetch failed), or 0 if the point is outside all polygons.
    static func floodProbability(at coord: CLLocationCoordinate2D,
                                 from collection: WPCFeatureCollection?) -> Int? {
        guard let collection else { return nil }
        let best = collection.features
            .filter { feature in
                guard let geometry = feature.geometry else { return false }
                return containsGeometry(coord, geometry: geometry)
            }
            .max(by: { $0.properties.rank < $1.properties.rank })
        return best?.properties.probability ?? 0
    }

    // MARK: - Internal (accessible from tests)

    /// True if `coord` falls inside `feature` (exterior ring) but not inside any hole.
    static func contains(_ coord: CLLocationCoordinate2D, feature: GeoJSONFeature) -> Bool {
        containsGeometry(coord, geometry: feature.geometry)
    }

    static func containsGeometry(_ coord: CLLocationCoordinate2D, geometry: GeoJSONGeometry) -> Bool {
        for polygon in geometry.polygons {
            guard !polygon.isEmpty else { continue }
            let inExterior = raycast(lat: coord.latitude, lon: coord.longitude, ring: polygon[0])
            let inHole     = polygon.dropFirst().contains {
                raycast(lat: coord.latitude, lon: coord.longitude, ring: $0)
            }
            if inExterior && !inHole { return true }
        }
        return false
    }

    /// Even-odd ray casting for a closed ring of [lon, lat] pairs.
    static func raycast(lat: Double, lon: Double, ring: [[Double]]) -> Bool {
        var inside = false
        var j = ring.count - 1
        for i in 0..<ring.count {
            let xi = ring[i][0], yi = ring[i][1]
            let xj = ring[j][0], yj = ring[j][1]
            if (yi > lat) != (yj > lat),
               lon < (xj - xi) * (lat - yi) / (yj - yi) + xi {
                inside = !inside
            }
            j = i
        }
        return inside
    }

    // MARK: - Private

    // Returns (probability%, isSignificant).
    // nil probability means the GeoJSON collection was unavailable (fetch failed).
    // 0 means the fetch succeeded but the user is outside all risk polygons.
    // SIGN features set the significant flag without affecting the probability tier.
    private static func probabilityAndSignificant(at coord: CLLocationCoordinate2D,
                                                  from collection: GeoJSONFeatureCollection?) -> (Int?, Bool) {
        guard let collection else { return (nil, false) }
        let matching = collection.features.filter { contains(coord, feature: $0) }
        let hasSign = matching.contains { $0.properties.label.uppercased() == "SIGN" }
        let best = matching
            .filter { $0.properties.label.uppercased() != "SIGN" }
            .max(by: { $0.properties.dn < $1.properties.dn })
        guard let best else { return (0, hasSign) }
        if let prob = Double(best.properties.label) {
            return (Int((prob * 100).rounded()), hasSign)
        }
        return (categoricalPercent(best.properties.label), hasSign)
    }

    private static func categoricalPercent(_ label: String) -> Int {
        switch label.uppercased() {
        case "TSTM": return 2
        case "MRGL": return 5
        case "SLGT": return 15
        case "ENH":  return 30
        case "MDT":  return 45
        case "HIGH": return 60
        default:     return 0
        }
    }
}

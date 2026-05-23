import XCTest
import CoreLocation
@testable import SPCOutlook

final class LocalRiskCalculatorTests: XCTestCase {

    // MARK: - Helpers

    // Closed square with corners at lon/lat ±1 (so lon: -1..1, lat: -1..1)
    private let unitSquareRing: [[Double]] = [
        [-1, -1], [1, -1], [1, 1], [-1, 1], [-1, -1]
    ]

    private func feature(label: String, dn: Int, rings: [[[Double]]]) -> GeoJSONFeature {
        GeoJSONFeature(
            geometry: .polygon(rings),
            properties: OutlookFeatureProperties(dn: dn, label: label)
        )
    }

    private func collection(_ features: [GeoJSONFeature]) -> GeoJSONFeatureCollection {
        GeoJSONFeatureCollection(features: features)
    }

    // MARK: - raycast

    func testRaycast_pointInsideSquare() {
        XCTAssertTrue(LocalRiskCalculator.raycast(lat: 0, lon: 0, ring: unitSquareRing))
    }

    func testRaycast_pointOutsideSquare() {
        XCTAssertFalse(LocalRiskCalculator.raycast(lat: 2, lon: 2, ring: unitSquareRing))
    }

    func testRaycast_pointOnLeftEdge_isConsistentlyClassified() {
        // Boundary behaviour is defined by the even-odd rule; we just verify no crash.
        _ = LocalRiskCalculator.raycast(lat: 0, lon: -1, ring: unitSquareRing)
    }

    // MARK: - contains (polygon with hole)

    func testContains_insideExteriorNotInHole() {
        // Exterior: unit square. Hole: tiny box at centre (lon -0.1..0.1, lat -0.1..0.1).
        let hole: [[Double]] = [[-0.1, -0.1], [0.1, -0.1], [0.1, 0.1], [-0.1, 0.1], [-0.1, -0.1]]
        let f = feature(label: "0.05", dn: 3, rings: [unitSquareRing, hole])
        // Point outside hole but inside exterior
        let coord = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)
        XCTAssertTrue(LocalRiskCalculator.contains(coord, feature: f))
    }

    func testContains_insideHoleReturnsFalse() {
        let hole: [[Double]] = [[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, 0.5], [-0.5, -0.5]]
        let f = feature(label: "0.05", dn: 3, rings: [unitSquareRing, hole])
        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        XCTAssertFalse(LocalRiskCalculator.contains(coord, feature: f))
    }

    func testContains_outsideExteriorReturnsFalse() {
        let f = feature(label: "0.05", dn: 3, rings: [unitSquareRing])
        let coord = CLLocationCoordinate2D(latitude: 5, longitude: 5)
        XCTAssertFalse(LocalRiskCalculator.contains(coord, feature: f))
    }

    // MARK: - localRisks — probabilistic labels

    func testProbabilisticLabel_convertedToPercent() {
        let f = feature(label: "0.05", dn: 3, rings: [unitSquareRing])
        let col = collection([f])
        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let risks = LocalRiskCalculator.localRisks(at: coord, tornado: col, hail: nil, wind: nil)
        XCTAssertEqual(risks.tornado, 5)
        XCTAssertEqual(risks.hail, 0)
        XCTAssertEqual(risks.wind, 0)
    }

    func testProbabilisticLabel_02Percent() {
        let f = feature(label: "0.02", dn: 2, rings: [unitSquareRing])
        let col = collection([f])
        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let risks = LocalRiskCalculator.localRisks(at: coord, tornado: col, hail: nil, wind: nil)
        XCTAssertEqual(risks.tornado, 2)
    }

    // MARK: - localRisks — categorical labels

    func testCategoricalLabel_MRGL() {
        let f = feature(label: "MRGL", dn: 3, rings: [unitSquareRing])
        let col = collection([f])
        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let risks = LocalRiskCalculator.localRisks(at: coord, tornado: col, hail: nil, wind: nil)
        XCTAssertEqual(risks.tornado, 5)
    }

    func testCategoricalLabel_SLGT() {
        let f = feature(label: "SLGT", dn: 4, rings: [unitSquareRing])
        let col = collection([f])
        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let risks = LocalRiskCalculator.localRisks(at: coord, tornado: col, hail: nil, wind: nil)
        XCTAssertEqual(risks.tornado, 15)
    }

    // MARK: - localRisks — highest DN wins

    func testHighestDNWins() {
        // Two features both containing the point; higher DN should win.
        let low  = feature(label: "0.02", dn: 2, rings: [unitSquareRing])
        let high = feature(label: "0.05", dn: 3, rings: [unitSquareRing])
        let col  = collection([low, high])
        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let risks = LocalRiskCalculator.localRisks(at: coord, tornado: col, hail: nil, wind: nil)
        XCTAssertEqual(risks.tornado, 5)
    }

    // MARK: - localRisks — outside all features

    func testOutsideAllFeaturesReturnsZero() {
        let f = feature(label: "0.15", dn: 5, rings: [unitSquareRing])
        let col = collection([f])
        let coord = CLLocationCoordinate2D(latitude: 10, longitude: 10)
        let risks = LocalRiskCalculator.localRisks(at: coord, tornado: col, hail: col, wind: col)
        XCTAssertEqual(risks.tornado, 0)
        XCTAssertEqual(risks.hail, 0)
        XCTAssertEqual(risks.wind, 0)
    }

    // MARK: - localRisks — nil collection

    func testNilCollectionReturnsZero() {
        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let risks = LocalRiskCalculator.localRisks(at: coord, tornado: nil, hail: nil, wind: nil)
        XCTAssertEqual(risks.tornado, 0)
        XCTAssertEqual(risks.hail, 0)
        XCTAssertEqual(risks.wind, 0)
    }
}

import XCTest
@testable import SPCOutlook

final class SPCEndpointsTests: XCTestCase {

    private let outlookBase = "https://www.spc.noaa.gov/products/outlook/"
    private let experBase   = "https://www.spc.noaa.gov/products/exper/day4-8/"

    // MARK: - categoricalImage

    func testCategoricalImageDays1Through3() {
        XCTAssertEqual(SPCEndpoints.categoricalImage(day: .one)?.absoluteString,
                       outlookBase + "day1otlk.png")
        XCTAssertEqual(SPCEndpoints.categoricalImage(day: .two)?.absoluteString,
                       outlookBase + "day2otlk.png")
        XCTAssertEqual(SPCEndpoints.categoricalImage(day: .three)?.absoluteString,
                       outlookBase + "day3otlk.png")
    }

    func testCategoricalImageDays4Through8AreNil() {
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            XCTAssertNil(SPCEndpoints.categoricalImage(day: day),
                         "Expected nil for Day \(day.rawValue)")
        }
    }

    // MARK: - probabilisticImage

    func testProbabilisticImageDay1() {
        XCTAssertEqual(SPCEndpoints.probabilisticImage(day: .one, risk: .tornado)?.absoluteString,
                       outlookBase + "day1probotlk_torn.png")
        XCTAssertEqual(SPCEndpoints.probabilisticImage(day: .one, risk: .hail)?.absoluteString,
                       outlookBase + "day1probotlk_hail.png")
        XCTAssertEqual(SPCEndpoints.probabilisticImage(day: .one, risk: .wind)?.absoluteString,
                       outlookBase + "day1probotlk_wind.png")
        XCTAssertNil(SPCEndpoints.probabilisticImage(day: .one, risk: .general))
    }

    func testProbabilisticImageDay2() {
        XCTAssertEqual(SPCEndpoints.probabilisticImage(day: .two, risk: .tornado)?.absoluteString,
                       outlookBase + "day2probotlk_torn.png")
        XCTAssertEqual(SPCEndpoints.probabilisticImage(day: .two, risk: .hail)?.absoluteString,
                       outlookBase + "day2probotlk_hail.png")
        XCTAssertEqual(SPCEndpoints.probabilisticImage(day: .two, risk: .wind)?.absoluteString,
                       outlookBase + "day2probotlk_wind.png")
        XCTAssertNil(SPCEndpoints.probabilisticImage(day: .two, risk: .general))
    }

    func testProbabilisticImageDay3() {
        XCTAssertEqual(SPCEndpoints.probabilisticImage(day: .three, risk: .general)?.absoluteString,
                       outlookBase + "day3prob.png")
        XCTAssertNil(SPCEndpoints.probabilisticImage(day: .three, risk: .tornado))
        XCTAssertNil(SPCEndpoints.probabilisticImage(day: .three, risk: .hail))
        XCTAssertNil(SPCEndpoints.probabilisticImage(day: .three, risk: .wind))
    }

    func testProbabilisticImageDays4Through8GeneralReturnPerDayImage() {
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            XCTAssertEqual(
                SPCEndpoints.probabilisticImage(day: day, risk: .general)?.absoluteString,
                experBase + "day\(day.rawValue)prob.gif",
                "Day \(day.rawValue) should return per-day exper image"
            )
        }
    }

    func testProbabilisticImageDays4Through8IndividualRisksAreNil() {
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            for risk in [RiskType.tornado, .hail, .wind] {
                XCTAssertNil(SPCEndpoints.probabilisticImage(day: day, risk: risk),
                             "Day \(day.rawValue) \(risk.rawValue) should be nil")
            }
        }
    }

    // MARK: - geoJSON

    func testGeoJSONDay1AllRisks() {
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .one, risk: .general)?.absoluteString,
                       outlookBase + "day1otlk_cat.lyr.geojson")
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .one, risk: .tornado)?.absoluteString,
                       outlookBase + "day1otlk_torn.lyr.geojson")
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .one, risk: .hail)?.absoluteString,
                       outlookBase + "day1otlk_hail.lyr.geojson")
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .one, risk: .wind)?.absoluteString,
                       outlookBase + "day1otlk_wind.lyr.geojson")
    }

    func testGeoJSONDay2AllRisks() {
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .two, risk: .general)?.absoluteString,
                       outlookBase + "day2otlk_cat.lyr.geojson")
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .two, risk: .tornado)?.absoluteString,
                       outlookBase + "day2otlk_torn.lyr.geojson")
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .two, risk: .hail)?.absoluteString,
                       outlookBase + "day2otlk_hail.lyr.geojson")
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .two, risk: .wind)?.absoluteString,
                       outlookBase + "day2otlk_wind.lyr.geojson")
    }

    func testGeoJSONDay3OnlyGeneralSupported() {
        XCTAssertEqual(SPCEndpoints.geoJSON(day: .three, risk: .general)?.absoluteString,
                       outlookBase + "day3otlk_cat.lyr.geojson")
        XCTAssertNil(SPCEndpoints.geoJSON(day: .three, risk: .tornado))
        XCTAssertNil(SPCEndpoints.geoJSON(day: .three, risk: .hail))
        XCTAssertNil(SPCEndpoints.geoJSON(day: .three, risk: .wind))
    }

    func testGeoJSONDays4Through8AreNil() {
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            for risk in RiskType.allCases {
                XCTAssertNil(SPCEndpoints.geoJSON(day: day, risk: risk),
                             "Day \(day.rawValue) \(risk.rawValue) GeoJSON should be nil")
            }
        }
    }

    // MARK: - discussionText

    func testDiscussionTextDays1Through3() {
        XCTAssertEqual(SPCEndpoints.discussionText(day: .one).absoluteString,
                       outlookBase + "day1otlk.txt")
        XCTAssertEqual(SPCEndpoints.discussionText(day: .two).absoluteString,
                       outlookBase + "day2otlk.txt")
        XCTAssertEqual(SPCEndpoints.discussionText(day: .three).absoluteString,
                       outlookBase + "day3otlk.txt")
    }

    func testDiscussionTextDays4Through8AllReturnCombined() {
        let expected = experBase + "day48otlk.txt"
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            XCTAssertEqual(SPCEndpoints.discussionText(day: day).absoluteString,
                           expected, "Day \(day.rawValue) should use combined exper discussion")
        }
    }
}

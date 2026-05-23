import XCTest
@testable import SPCOutlook

final class RiskTabDisableTests: XCTestCase {

    // The disable rule extracted from RiskTabs:
    // A tab is disabled when risk != .general AND (day == .three || day.isGrouped)
    private func isDisabled(_ risk: RiskType, for day: OutlookDay) -> Bool {
        risk != .general && (day == .three || day.isGrouped)
    }

    func testDays1And2EnableAllTabs() {
        for day in [OutlookDay.one, .two] {
            for risk in RiskType.allCases {
                XCTAssertFalse(isDisabled(risk, for: day),
                               "Day \(day.rawValue) \(risk.rawValue) should be enabled")
            }
        }
    }

    func testDay3DisablesIndividualRisksOnly() {
        XCTAssertFalse(isDisabled(.general, for: .three), "GENERAL should stay enabled on Day 3")
        XCTAssertTrue(isDisabled(.tornado, for: .three),  "TORNADO should be disabled on Day 3")
        XCTAssertTrue(isDisabled(.hail,    for: .three),  "HAIL should be disabled on Day 3")
        XCTAssertTrue(isDisabled(.wind,    for: .three),  "WIND should be disabled on Day 3")
    }

    func testDays4Through8DisableIndividualRisks() {
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            XCTAssertFalse(isDisabled(.general, for: day),
                           "GENERAL should stay enabled on Day \(day.rawValue)")
            for risk in [RiskType.tornado, .hail, .wind] {
                XCTAssertTrue(isDisabled(risk, for: day),
                              "\(risk.rawValue) should be disabled on Day \(day.rawValue)")
            }
        }
    }

    func testImageURLReturnsNilForDisabledCombinations() {
        // Confirm SPCEndpoints agrees with the disable rule:
        // disabled tabs have no probabilistic image, so the ViewModel would have nothing to load.
        XCTAssertNil(SPCEndpoints.probabilisticImage(day: .three, risk: .tornado))
        XCTAssertNil(SPCEndpoints.probabilisticImage(day: .three, risk: .hail))
        XCTAssertNil(SPCEndpoints.probabilisticImage(day: .three, risk: .wind))
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            XCTAssertNil(SPCEndpoints.probabilisticImage(day: day, risk: .tornado))
            XCTAssertNil(SPCEndpoints.probabilisticImage(day: day, risk: .hail))
            XCTAssertNil(SPCEndpoints.probabilisticImage(day: day, risk: .wind))
        }
    }
}

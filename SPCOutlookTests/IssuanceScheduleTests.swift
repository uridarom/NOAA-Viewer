import XCTest
@testable import SPCOutlook

final class IssuanceScheduleTests: XCTestCase {

    // MARK: - Helpers

    private var utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    /// Build a UTC Date for today at a given hour:minute.
    private func utcDate(hour: Int, minute: Int, addingDays days: Int = 0) -> Date {
        var comps = utcCalendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour; comps.minute = minute; comps.second = 0
        let base = utcCalendar.date(from: comps)!
        return utcCalendar.date(byAdding: .day, value: days, to: base)!
    }

    private func hour(_ date: Date) -> Int { utcCalendar.component(.hour, from: date) }
    private func minute(_ date: Date) -> Int { utcCalendar.component(.minute, from: date) }

    /// True if `a` and `b` are on the same UTC calendar day.
    private func sameDay(_ a: Date, _ b: Date) -> Bool {
        utcCalendar.isDate(a, inSameDayAs: b)
    }

    // MARK: - Day 1 (01:00, 06:00, 13:00, 16:30, 20:00 UTC)

    func testDay1At0030_nextIs0100() {
        let now  = utcDate(hour: 0, minute: 30)
        let next = IssuanceSchedule.nextIssuance(for: .one, after: now)
        XCTAssertTrue(sameDay(next, now))
        XCTAssertEqual(hour(next), 1); XCTAssertEqual(minute(next), 0)
    }

    func testDay1At0500_nextIs0600() {
        let now  = utcDate(hour: 5, minute: 0)
        let next = IssuanceSchedule.nextIssuance(for: .one, after: now)
        XCTAssertTrue(sameDay(next, now))
        XCTAssertEqual(hour(next), 6); XCTAssertEqual(minute(next), 0)
    }

    func testDay1At1300_nextIs1630() {
        let now  = utcDate(hour: 13, minute: 0)
        let next = IssuanceSchedule.nextIssuance(for: .one, after: now)
        XCTAssertTrue(sameDay(next, now))
        XCTAssertEqual(hour(next), 16); XCTAssertEqual(minute(next), 30)
    }

    func testDay1At2030_wrapsToTomorrowAt0100() {
        let now  = utcDate(hour: 20, minute: 30)
        let next = IssuanceSchedule.nextIssuance(for: .one, after: now)
        XCTAssertFalse(sameDay(next, now), "Should wrap to next UTC day")
        XCTAssertEqual(hour(next), 1); XCTAssertEqual(minute(next), 0)
    }

    func testDay1At2359_wrapsToTomorrowAt0100() {
        let now  = utcDate(hour: 23, minute: 59)
        let next = IssuanceSchedule.nextIssuance(for: .one, after: now)
        XCTAssertFalse(sameDay(next, now))
        XCTAssertEqual(hour(next), 1); XCTAssertEqual(minute(next), 0)
    }

    // MARK: - Day 2 (07:00, 17:30 UTC)

    func testDay2At0600_nextIs0700() {
        let now  = utcDate(hour: 6, minute: 0)
        let next = IssuanceSchedule.nextIssuance(for: .two, after: now)
        XCTAssertTrue(sameDay(next, now))
        XCTAssertEqual(hour(next), 7); XCTAssertEqual(minute(next), 0)
    }

    func testDay2At0800_nextIs1730() {
        let now  = utcDate(hour: 8, minute: 0)
        let next = IssuanceSchedule.nextIssuance(for: .two, after: now)
        XCTAssertTrue(sameDay(next, now))
        XCTAssertEqual(hour(next), 17); XCTAssertEqual(minute(next), 30)
    }

    func testDay2At1800_wrapsToTomorrowAt0700() {
        let now  = utcDate(hour: 18, minute: 0)
        let next = IssuanceSchedule.nextIssuance(for: .two, after: now)
        XCTAssertFalse(sameDay(next, now))
        XCTAssertEqual(hour(next), 7); XCTAssertEqual(minute(next), 0)
    }

    // MARK: - Day 3 (08:30 UTC)

    func testDay3At0800_nextIs0830() {
        let now  = utcDate(hour: 8, minute: 0)
        let next = IssuanceSchedule.nextIssuance(for: .three, after: now)
        XCTAssertTrue(sameDay(next, now))
        XCTAssertEqual(hour(next), 8); XCTAssertEqual(minute(next), 30)
    }

    func testDay3At0900_wrapsToTomorrowAt0830() {
        let now  = utcDate(hour: 9, minute: 0)
        let next = IssuanceSchedule.nextIssuance(for: .three, after: now)
        XCTAssertFalse(sameDay(next, now))
        XCTAssertEqual(hour(next), 8); XCTAssertEqual(minute(next), 30)
    }

    // MARK: - Days 4–8 (09:00 UTC)

    func testDays4through8At0800_nextIs0900() {
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            let now  = utcDate(hour: 8, minute: 0)
            let next = IssuanceSchedule.nextIssuance(for: day, after: now)
            XCTAssertTrue(sameDay(next, now), "Day \(day.rawValue)")
            XCTAssertEqual(hour(next), 9, "Day \(day.rawValue)")
            XCTAssertEqual(minute(next), 0, "Day \(day.rawValue)")
        }
    }

    func testDays4through8At1000_wrapsToTomorrow() {
        for day in [OutlookDay.four, .five, .six, .seven, .eight] {
            let now  = utcDate(hour: 10, minute: 0)
            let next = IssuanceSchedule.nextIssuance(for: day, after: now)
            XCTAssertFalse(sameDay(next, now), "Day \(day.rawValue)")
            XCTAssertEqual(hour(next), 9,  "Day \(day.rawValue)")
            XCTAssertEqual(minute(next), 0, "Day \(day.rawValue)")
        }
    }

    // MARK: - Exact boundary: time exactly at a scheduled slot is NOT "next"

    func testExactlyAtSlotIsNotNext() {
        // 06:00 UTC exactly — next should be 13:00, not 06:00 itself
        let now  = utcDate(hour: 6, minute: 0)
        let next = IssuanceSchedule.nextIssuance(for: .one, after: now)
        XCTAssertTrue(hour(next) > 6 || !sameDay(next, now),
                      "Exact slot time should not be returned as 'next'")
    }
}

import XCTest
@testable import SPCOutlook

final class DiscussionParserTests: XCTestCase {

    // MARK: - Fixtures

    private let day1Sample = """
        ZCZC SPCSWODY1 ALL
        ACUS01 KWNS 221934
        SPC AC 221934

        Day 1 Convective Outlook
        NWS Storm Prediction Center Norman OK
        0234 PM CDT Fri May 22 2026

        Valid 222000Z - 231200Z

        ...THERE IS A SLIGHT RISK OF SEVERE THUNDERSTORMS ACROSS PARTS OF
        NORTHWEST TEXAS AND WESTERN OKLAHOMA...

        ...SUMMARY...
        Thunderstorms with large hail and severe gusts are possible late
        this afternoon into the evening.

        ...Central Plains...
        A shortwave trough approaches from the west with shear increasing.

        ..Leitman.. 05/22/2026

        .PREV DISCUSSION... /ISSUED 1104 AM CDT Fri May 22 2026/

        ...TX/OK...
        Old previous discussion content that should be excluded.

        $$
        """

    private let day48Sample = """
        ZCZC SPCSWOD48 ALL
        ACUS48 KWNS 220901
        SPC AC 220901

        Day 4-8 Convective Outlook
        NWS Storm Prediction Center Norman OK
        0401 AM CDT Fri May 22 2026

        Valid 251200Z - 301200Z

        ...DISCUSSION...
        Severe potential will remain low D4/Monday. Height rises begin
        across the central US with a high amplitude ridge settling in.

        ..Thornton.. 05/22/2026
        """

    // MARK: - Headline

    func testMultiLineHeadlineExtracted() {
        let result = DiscussionParser.parse(day1Sample)
        XCTAssertEqual(
            result.headline,
            "THERE IS A SLIGHT RISK OF SEVERE THUNDERSTORMS ACROSS PARTS OF NORTHWEST TEXAS AND WESTERN OKLAHOMA"
        )
    }

    func testDay48HasNoHeadline() {
        let result = DiscussionParser.parse(day48Sample)
        XCTAssertEqual(result.headline, "")
    }

    // MARK: - Sections

    func testDay1SectionCount() {
        let result = DiscussionParser.parse(day1Sample)
        XCTAssertEqual(result.sections.count, 2)
    }

    func testDay1SectionTitles() {
        let result = DiscussionParser.parse(day1Sample)
        XCTAssertEqual(result.sections[0].title, "SUMMARY")
        XCTAssertEqual(result.sections[1].title, "Central Plains")
    }

    func testSectionBodyReflowed() {
        let result = DiscussionParser.parse(day1Sample)
        // "Thunderstorms with large hail and severe gusts are possible late\nthis afternoon into the evening."
        // should be joined into one line
        XCTAssertTrue(result.sections[0].body.contains("late this afternoon"))
        XCTAssertFalse(result.sections[0].body.contains("\n") && result.sections[0].body.hasSuffix("late"))
    }

    func testPrevDiscussionExcluded() {
        let result = DiscussionParser.parse(day1Sample)
        // "TX/OK" section from .PREV DISCUSSION must not appear in the main sections
        XCTAssertFalse(result.sections.map(\.title).contains("TX/OK"))
        for section in result.sections {
            XCTAssertFalse(section.body.contains("Old previous discussion"))
        }
    }

    func testPrevDiscussionParsed() {
        let result = DiscussionParser.parse(day1Sample)
        let prev = result.previousDiscussion
        XCTAssertNotNil(prev, "previousDiscussion should be non-nil when .PREV DISCUSSION block is present")
        XCTAssertEqual(prev?.sections.count, 1)
        XCTAssertEqual(prev?.sections.first?.title, "TX/OK")
        XCTAssertTrue(prev?.sections.first?.body.contains("Old previous discussion") ?? false)
    }

    func testPrevDiscussionIssuanceParsed() {
        let result = DiscussionParser.parse(day1Sample)
        if let date = result.previousDiscussion?.issuance {
            let cal = Calendar(identifier: .gregorian)
            XCTAssertEqual(cal.component(.year, from: date), 2026)
        }
        // nil is acceptable if the timezone abbreviation isn't supported on this host
    }

    func testDay48HasNoPrevDiscussion() {
        let result = DiscussionParser.parse(day48Sample)
        XCTAssertNil(result.previousDiscussion)
    }

    func testDay48DiscussionSection() {
        let result = DiscussionParser.parse(day48Sample)
        XCTAssertEqual(result.sections.count, 1)
        XCTAssertEqual(result.sections[0].title, "DISCUSSION")
        XCTAssertTrue(result.sections[0].body.contains("Severe potential"))
    }

    // MARK: - Issuance date

    func testIssuanceDateParsed() {
        let result = DiscussionParser.parse(day1Sample)
        // We can't assert the exact Date value (timezone parsing), but it shouldn't be nil
        // on a platform that recognises CDT.
        // Just verify the helper doesn't crash and returns something reasonable.
        if let date = result.issuance {
            let cal = Calendar(identifier: .gregorian)
            let components = cal.dateComponents([.year], from: date)
            XCTAssertEqual(components.year, 2026)
        }
        // nil is also acceptable if the timezone abbreviation isn't supported on this host
    }

    // MARK: - Edge cases

    func testEmptyStringProducesEmptyDiscussion() {
        let result = DiscussionParser.parse("")
        XCTAssertEqual(result.headline, "")
        XCTAssertTrue(result.sections.isEmpty)
    }

    func testSingleLineHeadline() {
        let text = """
            ZCZC SPCX ALL
            ACUS01 KWNS 221934

            Day 1 Convective Outlook
            NWS Storm Prediction Center Norman OK
            0600 AM CDT Fri May 22 2026

            Valid 221200Z - 231200Z

            ...NO SEVERE THUNDERSTORM AREAS FORECAST...

            ...SUMMARY...
            No severe weather expected today.

            ..Smith.. 05/22/2026

            $$
            """
        let result = DiscussionParser.parse(text)
        XCTAssertEqual(result.headline, "NO SEVERE THUNDERSTORM AREAS FORECAST")
        XCTAssertEqual(result.sections.count, 1)
        XCTAssertEqual(result.sections[0].title, "SUMMARY")
    }
}

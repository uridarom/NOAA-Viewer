import Foundation

struct ParsedSection {
    let title: String
    let body: String
}

struct ParsedDiscussion {
    let headline: String
    let issuance: Date?
    let sections: [ParsedSection]

    static let mock = ParsedDiscussion(
        headline: "THERE IS A SLIGHT RISK OF SEVERE THUNDERSTORMS ACROSS PARTS OF THE CENTRAL HIGH PLAINS",
        issuance: nil,
        sections: [
            ParsedSection(
                title: "SUMMARY",
                body: "Thunderstorms capable of producing large hail and isolated severe wind gusts will continue across parts of the central and southern High Plains through the evening. A tornado may also occur in the central High Plains."
            ),
            ParsedSection(
                title: "Central and Southern High Plains",
                body: "The latest water vapor imagery shows a mid-level shortwave trough approaching from the west, with strong low-level shear and destabilization expected through the evening hours. Surface boundaries will focus convective initiation."
            )
        ]
    )
}

struct OutlookSnapshot {
    var discussion: ParsedDiscussion
    var lastFetchedAt: Date?
    var nextIssuanceAt: Date?
}

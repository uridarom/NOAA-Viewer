import Foundation

enum DiscussionParser {

    static func parse(_ text: String) -> ParsedDiscussion {
        let lines = text.components(separatedBy: "\n")
        var idx = 0

        // ── 1. Skip WMO header to the product title line ("Day N…") ──────────
        while idx < lines.count, !lines[idx].hasPrefix("Day ") { idx += 1 }
        idx += 1  // skip product title

        // ── 2. Skip "NWS Storm Prediction Center" line ────────────────────────
        if idx < lines.count, lines[idx].contains("Storm Prediction Center") { idx += 1 }

        // ── 3. Skip blanks, then parse issuance timestamp ─────────────────────
        while idx < lines.count, lines[idx].trimmed.isEmpty { idx += 1 }
        let issuance = idx < lines.count ? parseDate(lines[idx]) : nil
        idx += 1

        // ── 4. Skip to and past "Valid …" line, then skip blank lines ─────────
        while idx < lines.count, !lines[idx].hasPrefix("Valid") { idx += 1 }
        idx += 1
        while idx < lines.count, lines[idx].trimmed.isEmpty { idx += 1 }

        // ── 5. Parse headline (present on Days 1–3, absent on Day 4–8) ────────
        //  Rules:
        //  • If the current line starts with "..." but does NOT end with "..."
        //    → multi-line headline; collect until blank line.
        //  • If it starts AND ends with "..." and the very next line is blank
        //    → single-line headline.
        //  • Otherwise (single-line section header followed by body text)
        //    → no headline; leave idx pointing at the section header.
        var headline = ""
        if idx < lines.count, lines[idx].hasPrefix("...") {
            let first = lines[idx]
            if !first.hasSuffix("...") {
                // Multi-line headline
                var buf: [String] = []
                while idx < lines.count, !lines[idx].trimmed.isEmpty { buf.append(lines[idx]); idx += 1 }
                headline = extractHeadline(buf)
            } else {
                // Peek: blank next line → single-line headline
                let nextIsBlank = (idx + 1 >= lines.count) || lines[idx + 1].trimmed.isEmpty
                if nextIsBlank {
                    headline = stripDots(first)
                    idx += 1
                }
                // else: first section header — no headline, leave idx here
            }
            // Skip blank lines after headline
            while idx < lines.count, lines[idx].trimmed.isEmpty { idx += 1 }
        }

        // ── 6. Parse sections ──────────────────────────────────────────────────
        var sections: [ParsedSection] = []

        while idx < lines.count {
            let trimmed = lines[idx].trimmed

            // Hard stops
            if trimmed == "$$" || trimmed.hasPrefix(".PREV DISCUSSION") { break }
            // Author line: starts with ".." but not "..."  (e.g. "..Leitman.. 05/22/2026")
            if trimmed.hasPrefix(".."), !trimmed.hasPrefix("...") { break }

            if isSectionHeader(trimmed) {
                let title = stripDots(trimmed)
                idx += 1
                var body: [String] = []
                while idx < lines.count {
                    let bt = lines[idx].trimmed
                    if bt == "$$" || bt.hasPrefix(".PREV DISCUSSION") { break }
                    if bt.hasPrefix(".."), !bt.hasPrefix("...") { break }
                    if isSectionHeader(bt) { break }
                    body.append(lines[idx])
                    idx += 1
                }
                let reflowed = reflow(body)
                if !reflowed.isEmpty {
                    sections.append(ParsedSection(title: title, body: reflowed))
                }
            } else {
                idx += 1  // non-header non-blank line outside a section — skip
            }
        }

        return ParsedDiscussion(headline: headline, issuance: issuance, sections: sections)
    }

    // MARK: - Helpers

    /// A section header is a line that starts AND ends with "..." with content between.
    private static func isSectionHeader(_ trimmed: String) -> Bool {
        trimmed.hasPrefix("...") && trimmed.hasSuffix("...") && trimmed.count > 6
    }

    private static func stripDots(_ s: String) -> String {
        var r = s
        while r.hasPrefix("...") { r = String(r.dropFirst(3)) }
        while r.hasSuffix("...") { r = String(r.dropLast(3)) }
        return r.trimmingCharacters(in: .whitespaces)
    }

    /// Join a multi-line headline block into a single string, stripping the
    /// leading "..." from the first line and trailing "..." from the last.
    private static func extractHeadline(_ lines: [String]) -> String {
        guard !lines.isEmpty else { return "" }
        var parts = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        parts[0] = parts[0].hasPrefix("...") ? String(parts[0].dropFirst(3)) : parts[0]
        if var last = parts.last, last.hasSuffix("...") {
            last = String(last.dropLast(3))
            parts[parts.count - 1] = last
        }
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    /// Replace single newlines with spaces within paragraphs; double newlines
    /// become paragraph separators (a single "\n\n").
    private static func reflow(_ lines: [String]) -> String {
        var paragraphs: [String] = []
        var current: [String] = []
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty {
                if !current.isEmpty { paragraphs.append(current.joined(separator: " ")); current = [] }
            } else {
                current.append(t)
            }
        }
        if !current.isEmpty { paragraphs.append(current.joined(separator: " ")) }
        return paragraphs.joined(separator: "\n\n")
    }

    /// Parse SPC issuance timestamps like "0234 PM CDT Fri May 22 2026".
    static func parseDate(_ line: String) -> Date? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 4 else { return nil }
        // Insert colon between hour and minute: "0234 PM…" → "02:34 PM…"
        let withColon = String(trimmed.prefix(2)) + ":" + trimmed.dropFirst(2)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a zzz EEE MMM d yyyy"
        return formatter.date(from: withColon)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
}

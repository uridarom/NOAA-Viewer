import Foundation

/// UTC issuance schedule per §1.4.
enum IssuanceSchedule {

    // MARK: - Schedule data

    private struct TimeUTC {
        let hour: Int
        let minute: Int
    }

    /// Scheduled issuance times in UTC, sorted ascending within a calendar day.
    private static func times(for day: OutlookDay) -> [TimeUTC] {
        switch day {
        case .one:
            // 01:00, 06:00, 13:00, 16:30, 20:00 UTC (01:00 wraps to the next UTC day)
            return [.init(hour: 1, minute: 0), .init(hour: 6, minute: 0),
                    .init(hour: 13, minute: 0), .init(hour: 16, minute: 30),
                    .init(hour: 20, minute: 0)]
        case .two:
            return [.init(hour: 7, minute: 0), .init(hour: 17, minute: 30)]
        case .three:
            return [.init(hour: 8, minute: 30)]
        default:          // Days 4–8 share the same daily issuance
            return [.init(hour: 9, minute: 0)]
        }
    }

    // MARK: - Public API

    /// Returns the next scheduled issuance time strictly after `now` (UTC),
    /// rolling to the following calendar day if all of today's slots are past.
    static func nextIssuance(for day: OutlookDay, after now: Date = Date()) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!

        let slots = times(for: day)

        // Search today's UTC slots
        for slot in slots {
            var comps = cal.dateComponents([.year, .month, .day], from: now)
            comps.hour = slot.hour; comps.minute = slot.minute; comps.second = 0
            if let candidate = cal.date(from: comps), candidate > now {
                return candidate
            }
        }

        // All of today's slots are past — use the first slot tomorrow
        let todayStart = cal.startOfDay(for: now)
        let tomorrow   = cal.date(byAdding: .day, value: 1, to: todayStart)!
        var comps = cal.dateComponents([.year, .month, .day], from: tomorrow)
        comps.hour = slots[0].hour; comps.minute = slots[0].minute; comps.second = 0
        return cal.date(from: comps)!
    }
}

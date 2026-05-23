import Foundation

enum OutlookDay: Int, CaseIterable, Identifiable, Codable {
    case one = 1, two, three, four, five, six, seven, eight

    var id: Int { rawValue }
    var title: String { "Day \(rawValue)" }
    var isGrouped: Bool { rawValue >= 4 }
}

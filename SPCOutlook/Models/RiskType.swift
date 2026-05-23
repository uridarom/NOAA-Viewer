import Foundation

enum RiskType: String, CaseIterable, Identifiable, Codable {
    case general, tornado, hail, wind

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general:  return "GENERAL"
        case .tornado:  return "TORNADO"
        case .hail:     return "HAIL"
        case .wind:     return "WIND"
        }
    }
}

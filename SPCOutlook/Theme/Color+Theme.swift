import SwiftUI

extension Color {
    static let bgPrimary      = Color(hex: "000000")
    static let bgCard         = Color(hex: "141414")
    static let bgTabSelected  = Color(hex: "2A2A2A")
    static let bgTabUnselected = Color(hex: "0F0F0F")

    static let textPrimary    = Color(hex: "FFFFFF")
    static let textSecondary  = Color(hex: "FFFFFF")
    static let textTertiary   = Color(hex: "5A5A5A")

    static let accentRisk     = Color(hex: "E89B9B")
    static let accentSafe     = Color(hex: "7CB97C")
    static let accentAmber    = Color(hex: "E8C88C")
    static let accentDeepRed  = Color(hex: "E85050")

    static let dividerColor   = Color(hex: "2A2A2A")

    static func riskColor(for percentage: Int) -> Color {
        switch percentage {
        case 0:        return .textTertiary
        case 1...9:    return .accentSafe
        case 10...29:  return .accentAmber
        case 30...59:  return .accentRisk
        default:       return .accentDeepRed
        }
    }

    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >>  8) & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

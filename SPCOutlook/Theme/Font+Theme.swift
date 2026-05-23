import SwiftUI

extension Font {
    static func courier(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Courier New", size: size).weight(weight)
    }
}

import CoreGraphics

// Equirectangular approximation of the SPC Day 1–3 outlook image bounds.
// Accurate enough for local-view centering; avoids the full LCC implementation.
enum SPCProjection {
    private static let west:  Double = -122.0
    private static let east:  Double =  -60.0
    private static let north: Double =   50.0
    private static let south: Double =   20.0

    /// Returns a (0,0)–(1,1) position where (0,0) is top-left of the image.
    static func normalizedPosition(lat: Double, lon: Double) -> CGPoint {
        let x = (lon - west)  / (east  - west)
        let y = (north - lat) / (north - south)
        return CGPoint(x: max(0, min(1, x)), y: max(0, min(1, y)))
    }
}

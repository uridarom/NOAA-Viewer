import Foundation

enum WPCEndpoints {
    private static let base = "https://mapservices.weather.noaa.gov/vector/rest/services/hazards/wpc_precip_hazards/MapServer"

    /// Day 1 Excessive Rainfall Outlook polygons as GeoJSON (ArcGIS REST layer 0).
    static var eroDay1GeoJSON: URL? {
        URL(string: "\(base)/0/query?where=1%3D1&outFields=*&f=geojson&returnGeometry=true")
    }
}

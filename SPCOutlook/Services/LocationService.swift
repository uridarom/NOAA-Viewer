import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus

    private let manager: CLLocationManager
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestLocation() async -> CLLocationCoordinate2D? {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Wait for authorization before requesting location
            return await withCheckedContinuation { continuation in
                locationContinuation = continuation
            }
        case .authorizedWhenInUse, .authorizedAlways:
            return await withCheckedContinuation { continuation in
                locationContinuation = continuation
                manager.requestLocation()
            }
        default:
            return nil
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let coord = loc.coordinate
        Task { @MainActor in
            self.coordinate = coord
            self.locationContinuation?.resume(returning: coord)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                // Authorization just granted — fulfill the pending continuation
                if self.locationContinuation != nil {
                    manager.requestLocation()
                }
            case .denied, .restricted:
                self.locationContinuation?.resume(returning: nil)
                self.locationContinuation = nil
            default:
                break
            }
        }
    }
}

import Combine
import CoreLocation
import Foundation

final class TrackingService: NSObject, ObservableObject {
    @Published private(set) var coordinate: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isLive: Bool = false
    @Published private(set) var distanceMetersToday: Double = 0
    @Published private(set) var travelMode: TravelMode = .unknown

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var distanceDay = Calendar.current.startOfDay(for: Date())

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func startLiveTracking(enabled: Bool) {
        guard enabled else {
            manager.stopUpdatingLocation()
            isLive = false
            return
        }
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            requestWhenInUse()
            return
        }
        manager.startUpdatingLocation()
        isLive = true
    }

    var travelModeLabel: String {
        switch travelMode {
        case .stationary:
            return "Stopped"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .rideshare:
            return "Rideshare"
        case .driving:
            return "Driving"
        case .flying:
            return "Flying"
        case .unknown:
            return "Unknown"
        }
    }

    var travelModeIcon: String {
        switch travelMode {
        case .stationary:
            return "pause.circle"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "bicycle"
        case .rideshare:
            return "car"
        case .driving:
            return "car.fill"
        case .flying:
            return "airplane"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

enum TravelMode: String {
    case stationary
    case walking
    case cycling
    case rideshare
    case driving
    case flying
    case unknown
}

extension TrackingService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        coordinate = last.coordinate
        updateDistance(with: last)
        updateTravelMode(with: last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLive = false
    }

    private func updateDistance(with location: CLLocation) {
        let startOfDay = Calendar.current.startOfDay(for: location.timestamp)
        if startOfDay != distanceDay {
            distanceDay = startOfDay
            distanceMetersToday = 0
            lastLocation = location
            return
        }

        guard let last = lastLocation else {
            lastLocation = location
            return
        }

        let delta = location.distance(from: last)
        if delta >= 8 && delta < 5000 {
            distanceMetersToday += delta
        }
        lastLocation = location
    }

    private func updateTravelMode(with location: CLLocation) {
        let speed = max(0, location.speed)
        let newMode: TravelMode
        switch speed {
        case ..<0.5:
            newMode = .stationary
        case ..<2.2:
            newMode = .walking
        case ..<6.0:
            newMode = .cycling
        case ..<20.0:
            newMode = .rideshare
        case ..<55.0:
            newMode = .driving
        default:
            newMode = .flying
        }
        travelMode = newMode
    }
}

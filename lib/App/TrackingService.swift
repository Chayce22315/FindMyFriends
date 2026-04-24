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
    private var wantsLiveTracking = false
    private var allowBackground = false
    private let defaults = UserDefaults.standard
    private let distanceKey = "fmf.tracking.distanceMetersToday"
    private let distanceDayKey = "fmf.tracking.distanceDay"

    /// Ignore GPS noise when sitting still: require meaningful movement before counting distance.
    private let minMovementMeters: CLLocationDistance = 22
    private let maxPlausibleJumpMeters: CLLocationDistance = 4_000
    /// Reject fixes worse than this horizontal accuracy (meters) for odometer math.
    private let maxHorizontalAccuracyMeters: CLLocationDistance = 65

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.activityType = .fitness
        manager.distanceFilter = 25
        authorizationStatus = manager.authorizationStatus
        loadDistanceCache()
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    func startLiveTracking(enabled: Bool, allowBackground: Bool = false) {
        wantsLiveTracking = enabled
        self.allowBackground = allowBackground

        guard enabled else {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
            isLive = false
            return
        }

        if allowBackground {
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
            requestAlways()
        } else {
            manager.allowsBackgroundLocationUpdates = false
            manager.pausesLocationUpdatesAutomatically = true
            requestWhenInUse()
        }

        startIfAuthorized()
    }

    private func startIfAuthorized() {
        guard wantsLiveTracking else { return }
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else { return }
        manager.startUpdatingLocation()
        if allowBackground {
            manager.startMonitoringSignificantLocationChanges()
        }
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
        startIfAuthorized()
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
            persistDistance()
            return
        }

        guard let last = lastLocation else {
            lastLocation = location
            return
        }

        let delta = location.distance(from: last)

        let currentAcc = location.horizontalAccuracy
        let lastAcc = last.horizontalAccuracy
        let accuracyOK =
            currentAcc >= 0 && currentAcc <= maxHorizontalAccuracyMeters
            && lastAcc >= 0 && lastAcc <= maxHorizontalAccuracyMeters

        let speed = location.speed
        /// Below ~1 m/s Core Location usually means still or unreliable; require a larger delta so GPS drift does not add miles.
        let minDeltaForThisFix: CLLocationDistance = {
            if speed >= 1.0 { return minMovementMeters }
            if speed >= 0 { return 50 }
            return 60
        }()

        if accuracyOK,
           delta >= minDeltaForThisFix,
           delta < maxPlausibleJumpMeters {
            distanceMetersToday += delta
        }

        lastLocation = location
        persistDistance()
    }

    private func persistDistance() {
        defaults.set(distanceMetersToday, forKey: distanceKey)
        defaults.set(distanceDay, forKey: distanceDayKey)
    }

    private func loadDistanceCache() {
        guard let storedDay = defaults.object(forKey: distanceDayKey) as? Date else { return }
        let today = Calendar.current.startOfDay(for: Date())
        if storedDay == today {
            distanceDay = storedDay
            distanceMetersToday = defaults.double(forKey: distanceKey)
        }
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

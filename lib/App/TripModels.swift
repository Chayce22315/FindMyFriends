import Foundation
import MapKit

struct TripPoint: Identifiable, Hashable, Codable {
    var id: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date

    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D, timestamp: Date) {
        self.id = id
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = timestamp
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct TripStop: Identifiable, Hashable, Codable {
    var id: UUID
    let name: String
    let note: String
    let arrival: Date
    let durationMinutes: Int
    let latitude: Double
    let longitude: Double

    init(id: UUID = UUID(), name: String, note: String, arrival: Date, durationMinutes: Int, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.note = note
        self.arrival = arrival
        self.durationMinutes = durationMinutes
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Trip: Identifiable, Hashable, Codable {
    var id: UUID
    let title: String
    let date: Date
    let distanceKm: Double
    let mode: TripMode
    let summary: String
    let points: [TripPoint]
    let stops: [TripStop]

    init(id: UUID = UUID(), title: String, date: Date, distanceKm: Double, mode: TripMode, summary: String, points: [TripPoint], stops: [TripStop]) {
        self.id = id
        self.title = title
        self.date = date
        self.distanceKm = distanceKm
        self.mode = mode
        self.summary = summary
        self.points = points
        self.stops = stops
    }

    var distanceLabel: String {
        String(format: "%.1f km", distanceKm)
    }

    var polyline: MKPolyline {
        let coords = points.map { $0.coordinate }
        return MKPolyline(coordinates: coords, count: coords.count)
    }

    static let sample: [Trip] = {
        let base = Date()
        let samplePoints = [
            TripPoint(coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090), timestamp: base.addingTimeInterval(-1800)),
            TripPoint(coordinate: CLLocationCoordinate2D(latitude: 37.3365, longitude: -122.0122), timestamp: base.addingTimeInterval(-1500)),
            TripPoint(coordinate: CLLocationCoordinate2D(latitude: 37.3391, longitude: -122.0161), timestamp: base.addingTimeInterval(-1200)),
            TripPoint(coordinate: CLLocationCoordinate2D(latitude: 37.3432, longitude: -122.0180), timestamp: base.addingTimeInterval(-900)),
            TripPoint(coordinate: CLLocationCoordinate2D(latitude: 37.3471, longitude: -122.0201), timestamp: base.addingTimeInterval(-600)),
        ]
        let stops = [
            TripStop(name: "Coffee stop", note: "Quick latte", arrival: base.addingTimeInterval(-1400), durationMinutes: 12, coordinate: CLLocationCoordinate2D(latitude: 37.3365, longitude: -122.0122)),
            TripStop(name: "Overlook", note: "Scenic pause", arrival: base.addingTimeInterval(-900), durationMinutes: 8, coordinate: CLLocationCoordinate2D(latitude: 37.3432, longitude: -122.0180)),
        ]
        return [
            Trip(title: "Morning drive", date: base.addingTimeInterval(-3600 * 4), distanceKm: 12.6, mode: .driving, summary: "Smooth commute to HQ.", points: samplePoints, stops: stops),
            Trip(title: "Lunch walk", date: base.addingTimeInterval(-3600 * 6), distanceKm: 2.8, mode: .walking, summary: "Loop around the park.", points: samplePoints.reversed(), stops: []),
            Trip(title: "Evening ride", date: base.addingTimeInterval(-3600 * 9), distanceKm: 8.3, mode: .cycling, summary: "Golden hour ride.", points: samplePoints, stops: stops),
        ]
    }()
}

enum TripMode: String, CaseIterable, Codable {
    case walking
    case cycling
    case driving
    case rideshare
    case flight

    var label: String {
        switch self {
        case .walking: return "Walk"
        case .cycling: return "Cycle"
        case .driving: return "Drive"
        case .rideshare: return "Uber"
        case .flight: return "Fly"
        }
    }

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .driving: return "car.fill"
        case .rideshare: return "car"
        case .flight: return "airplane"
        }
    }
}

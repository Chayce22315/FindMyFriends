import Foundation

struct Journey: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let date: Date
    let distanceKm: Double
    let mode: JourneyMode
    let highlights: String

    var distanceLabel: String {
        String(format: "%.1f km", distanceKm)
    }

    static let sample: [Journey] = [
        Journey(title: "Morning commute", date: .now.addingTimeInterval(-3600 * 5), distanceKm: 12.6, mode: .driving, highlights: "Traffic was light."),
        Journey(title: "Late night walk", date: .now.addingTimeInterval(-3600 * 22), distanceKm: 3.4, mode: .walking, highlights: "Stopped by the lake."),
        Journey(title: "Weekend ride", date: .now.addingTimeInterval(-3600 * 36), distanceKm: 18.2, mode: .cycling, highlights: "New bike lane route."),
        Journey(title: "Family pickup", date: .now.addingTimeInterval(-3600 * 52), distanceKm: 7.8, mode: .rideshare, highlights: "Quick pickup run."),
        Journey(title: "Flight to Dallas", date: .now.addingTimeInterval(-3600 * 80), distanceKm: 1020, mode: .flight, highlights: "Altitude mode on."),
    ]
}

enum JourneyMode: String {
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

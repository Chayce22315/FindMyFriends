import Combine
import Foundation

final class TripStore: ObservableObject {
    @Published var trips: [Trip] {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private let key = "fmf.trips"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let data = defaults.data(forKey: key),
           let decoded = try? decoder.decode([Trip].self, from: data) {
            self.trips = decoded
        } else {
            self.trips = Trip.sample
        }
    }

    func filterTrips(_ filter: TripFilter) -> [Trip] {
        let calendar = Calendar.current
        switch filter {
        case .day:
            return trips.filter { calendar.isDateInToday($0.date) }
        case .week:
            return trips.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        case .month:
            return trips.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        }
    }

    private func save() {
        if let data = try? encoder.encode(trips) {
            defaults.set(data, forKey: key)
        }
    }
}

enum TripFilter: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

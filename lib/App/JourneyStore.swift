import Combine
import Foundation

final class JourneyStore: ObservableObject {
    @Published var journeys: [Journey] = Journey.sample

    var totalDistanceKm: Double {
        journeys.reduce(0) { $0 + $1.distanceKm }
    }
}

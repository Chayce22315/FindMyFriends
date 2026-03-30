import Combine
import Foundation

final class MovementXPService: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init(tracking: TrackingService, progress: UserProgressStore) {
        tracking.$distanceMetersToday
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { meters in
                progress.syncXPFromDistance(meters: meters, usesMetric: Locale.current.usesMetricSystem)
            }
            .store(in: &cancellables)
    }
}

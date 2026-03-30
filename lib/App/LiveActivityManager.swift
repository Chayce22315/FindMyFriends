import ActivityKit
import Combine
import Foundation

@MainActor
final class LiveActivityManager: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var statusLabel: String = "Idle"

    private var activity: Activity<FindMyFriendsLiveActivityAttributes>?
    private var cancellables = Set<AnyCancellable>()

    init(tracking: TrackingService, health: ActivityHealthService, progress: UserProgressStore) {
        tracking.$isLive
            .combineLatest(tracking.$travelMode, tracking.$distanceMetersToday, health.$stepsToday)
            .combineLatest(progress.$xp)
            .receive(on: RunLoop.main)
            .sink { [weak self] combined, xp in
                guard let self else { return }
                let (isLive, mode, distance, steps) = combined
                Task { await self.handleUpdate(isLive: isLive, mode: mode, distance: distance, steps: steps, xp: xp) }
            }
            .store(in: &cancellables)
    }

    private func handleUpdate(isLive: Bool, mode: TravelMode, distance: Double, steps: Int, xp: Int) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusLabel = "Live Activities disabled"
            return
        }

        if isLive {
            let state = FindMyFriendsLiveActivityAttributes.ContentState(
                status: modeStatus(mode),
                distance: distanceLabel(meters: distance),
                modeIcon: mode.icon,
                steps: stepsLabel(steps),
                xp: xpLabel(xp)
            )
            await startOrUpdate(state: state)
        } else {
            await end()
        }
    }

    private func startOrUpdate(state: FindMyFriendsLiveActivityAttributes.ContentState) async {
        if let activity {
            await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(300)))
            isRunning = true
            statusLabel = "Updating"
            return
        }

        do {
            let attributes = FindMyFriendsLiveActivityAttributes(name: "Find My Friends")
            activity = try Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil))
            isRunning = true
            statusLabel = "Running"
        } catch {
            statusLabel = "Live Activity failed"
        }
    }

    func end() async {
        guard let activity else { return }
        let state = FindMyFriendsLiveActivityAttributes.ContentState(
            status: "Paused",
            distance: "--",
            modeIcon: "pause.circle",
            steps: "--",
            xp: "--"
        )
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .default)
        self.activity = nil
        isRunning = false
        statusLabel = "Idle"
    }

    private func distanceLabel(meters: Double) -> String {
        let usesMetric = Locale.current.measurementSystem == .metric
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let converted = measurement.converted(to: usesMetric ? .kilometers : .miles)
        return String(format: "%.1f %@", converted.value, usesMetric ? "km" : "mi")
    }

    private func stepsLabel(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    private func xpLabel(_ xp: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: xp)) ?? "\(xp)"
    }

    private func modeStatus(_ mode: TravelMode) -> String {
        switch mode {
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
            return "Moving"
        }
    }
}

private extension TravelMode {
    var icon: String {
        switch self {
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
            return "location.circle"
        }
    }
}

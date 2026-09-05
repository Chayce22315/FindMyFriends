import ActivityKit
import Combine
import Foundation

@MainActor
final class LiveActivityManager: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var statusLabel = "Live Activity idle"

    private var activity: Activity<FindMyFriendsActivityAttributes>?

    init() {
        activity = Activity<FindMyFriendsActivityAttributes>.activities.first
        isRunning = activity != nil
        statusLabel = activity == nil ? "Live location is off" : "Movement status is live"
    }

    func startIfNeeded(xp: Int, distanceMeters: Double, travelMode: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            isRunning = false
            statusLabel = "Live Activities are disabled"
            return
        }

        if activity == nil {
            do {
                let attributes = FindMyFriendsActivityAttributes()
                let state = FindMyFriendsActivityAttributes.ContentState(
                    travelMode: travelMode,
                    distanceMeters: distanceMeters,
                    xp: xp,
                    isTracking: true
                )
                let content = ActivityContent(state: state, staleDate: nil)
                activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                isRunning = false
                statusLabel = "Could not start Live Activity"
                return
            }
        } else {
            update(xp: xp, distanceMeters: distanceMeters, travelMode: travelMode, isTracking: true)
        }

        isRunning = true
        statusLabel = "\(travelMode) • \(formattedDistance(distanceMeters)) today"
    }

    func update(xp: Int, distanceMeters: Double, travelMode: String, isTracking: Bool) {
        guard let activity else { return }

        let state = FindMyFriendsActivityAttributes.ContentState(
            travelMode: travelMode,
            distanceMeters: distanceMeters,
            xp: xp,
            isTracking: isTracking
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
        }

        isRunning = true
        statusLabel = isTracking
            ? "\(travelMode) • \(formattedDistance(distanceMeters)) today"
            : "Tracking paused"
    }

    func end() async {
        guard let activity else { return }
        let state = FindMyFriendsActivityAttributes.ContentState(
            travelMode: "Stopped",
            distanceMeters: activity.content.state.distanceMeters,
            xp: activity.content.state.xp,
            isTracking: false
        )
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .default)
        self.activity = nil
        isRunning = false
        statusLabel = "Live Activity idle"
    }

    private func formattedDistance(_ meters: Double) -> String {
        let miles = meters / 1_609.344
        if miles < 0.1 { return "\(Int(meters)) m" }
        return String(format: "%.1f mi", miles)
    }
}

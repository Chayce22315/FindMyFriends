import ActivityKit
import Foundation

public struct FindMyFriendsActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var travelMode: String
        public var distanceMeters: Double
        public var xp: Int
        public var isTracking: Bool

        public init(travelMode: String, distanceMeters: Double, xp: Int, isTracking: Bool) {
            self.travelMode = travelMode
            self.distanceMeters = distanceMeters
            self.xp = xp
            self.isTracking = isTracking
        }
    }

    public var startedAt: Date

    public init(startedAt: Date = Date()) {
        self.startedAt = startedAt
    }
}

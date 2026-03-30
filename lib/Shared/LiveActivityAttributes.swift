import ActivityKit
import Foundation

struct FindMyFriendsLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var distance: String
        var modeIcon: String
        var steps: String
        var xp: String
    }

    var name: String
}

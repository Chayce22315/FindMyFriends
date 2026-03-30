import Combine
import Foundation

final class AppSettings: ObservableObject {
    @Published var trackingEnabled: Bool {
        didSet { defaults.set(trackingEnabled, forKey: Keys.tracking) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let tracking = "fmf.settings.tracking"
        static let notifications = "fmf.settings.notifications"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.tracking) != nil {
            self.trackingEnabled = defaults.bool(forKey: Keys.tracking)
        } else {
            self.trackingEnabled = true
        }
        if defaults.object(forKey: Keys.notifications) != nil {
            self.notificationsEnabled = defaults.bool(forKey: Keys.notifications)
        } else {
            self.notificationsEnabled = true
        }
    }
}

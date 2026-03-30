import Combine
import Foundation

final class AppSettings: ObservableObject {
    @Published var trackingEnabled: Bool {
        didSet { defaults.set(trackingEnabled, forKey: Keys.tracking) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    @Published var backendBaseURL: String {
        didSet { defaults.set(backendBaseURL, forKey: Keys.backendBaseURL) }
    }

    @Published var backgroundXPEnabled: Bool {
        didSet { defaults.set(backgroundXPEnabled, forKey: Keys.backgroundXPEnabled) }
    }

    @Published var liquidGlassEnabled: Bool {
        didSet { defaults.set(liquidGlassEnabled, forKey: Keys.liquidGlass) }
    }

    private let defaults: UserDefaults

    static let defaultBackendBaseURL = "http://localhost:4000"

    private enum Keys {
        static let tracking = "fmf.settings.tracking"
        static let notifications = "fmf.settings.notifications"
        static let backendBaseURL = "fmf.settings.backendBaseURL"
        static let backgroundXPEnabled = "fmf.settings.backgroundXPEnabled"
        static let liquidGlass = "fmf.settings.liquidGlass"
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
        if let stored = defaults.string(forKey: Keys.backendBaseURL), !stored.isEmpty {
            self.backendBaseURL = stored
        } else {
            self.backendBaseURL = Self.defaultBackendBaseURL
        }
        if defaults.object(forKey: Keys.backgroundXPEnabled) != nil {
            self.backgroundXPEnabled = defaults.bool(forKey: Keys.backgroundXPEnabled)
        } else {
            self.backgroundXPEnabled = true
        }
        if defaults.object(forKey: Keys.liquidGlass) != nil {
            self.liquidGlassEnabled = defaults.bool(forKey: Keys.liquidGlass)
        } else {
            self.liquidGlassEnabled = true
        }
    }
}

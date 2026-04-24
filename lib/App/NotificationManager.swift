import Combine
import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private var notificationsEnabled = true
    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings? = nil) {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        refreshStatus()
        if let settings {
            notificationsEnabled = settings.notificationsEnabled
            settings.$notificationsEnabled
                .receive(on: RunLoop.main)
                .sink { [weak self] enabled in
                    self?.notificationsEnabled = enabled
                }
                .store(in: &cancellables)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLevelUp(_:)),
            name: .didLevelUp,
            object: nil
        )
    }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { ok, _ in
            DispatchQueue.main.async {
                self.refreshStatus()
                completion?(ok)
            }
        }
    }

    func scheduleLevelUp(level: Int) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Level up!"
        content.body = "You reached level \(level). Keep moving with your crew."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "fmf.levelup.\(level)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleReminder(title: String, body: String, in seconds: TimeInterval = 5) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleFamilyMemberJoined(displayName: String, familyName: String) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Someone joined \(familyName)"
        content.body = "\(displayName) is now in your Circle. Open the app to see everyone."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "fmf.join.\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    @objc private func handleLevelUp(_ note: Notification) {
        guard let level = note.object as? Int else { return }
        scheduleLevelUp(level: level)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

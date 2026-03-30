import SwiftUI

@main
struct FindMyFriendsApp: App {
    @StateObject private var session: AppSession
    @StateObject private var progress: UserProgressStore
    @StateObject private var health: ActivityHealthService
    @StateObject private var notifications: NotificationManager
    @StateObject private var tracking: TrackingService
    @StateObject private var contacts: ContactsFriendService
    @StateObject private var settings: AppSettings
    @StateObject private var music: MusicService
    @StateObject private var movementXP: MovementXPService
    @StateObject private var liveActivity: LiveActivityManager

    init() {
        let tracking = TrackingService()
        let progress = UserProgressStore()
        let health = ActivityHealthService()
        let settings = AppSettings()
        _session = StateObject(wrappedValue: AppSession())
        _progress = StateObject(wrappedValue: progress)
        _health = StateObject(wrappedValue: health)
        _notifications = StateObject(wrappedValue: NotificationManager(settings: settings))
        _tracking = StateObject(wrappedValue: tracking)
        _contacts = StateObject(wrappedValue: ContactsFriendService())
        _settings = StateObject(wrappedValue: settings)
        _music = StateObject(wrappedValue: MusicService())
        _movementXP = StateObject(wrappedValue: MovementXPService(tracking: tracking, progress: progress))
        _liveActivity = StateObject(wrappedValue: LiveActivityManager(tracking: tracking, health: health, progress: progress))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(progress)
                .environmentObject(health)
                .environmentObject(notifications)
                .environmentObject(tracking)
                .environmentObject(contacts)
                .environmentObject(settings)
                .environmentObject(music)
                .environmentObject(liveActivity)
                .preferredColorScheme(.dark)
        }
    }
}

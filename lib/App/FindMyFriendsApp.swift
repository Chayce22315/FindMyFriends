import SwiftUI

@main
struct FindMyFriendsApp: App {
    @StateObject private var session = AppSession()
    @StateObject private var progress = UserProgressStore()
    @StateObject private var health = ActivityHealthService()
    @StateObject private var notifications = NotificationManager()
    @StateObject private var tracking = TrackingService()
    @StateObject private var contacts = ContactsFriendService()
    @StateObject private var settings = AppSettings()

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
                .preferredColorScheme(.dark)
        }
    }
}

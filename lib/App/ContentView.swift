import SwiftUI

struct ContentView: View {
    @State private var tab: Tab = .map
    /// Set when user opens `findmyfriends://join?...` from the invite web page; Circle consumes it to join.
    @State private var pendingFamilyInviteCode: String?

    private enum Tab: Hashable {
        case map, places, trips, circle, move, you
    }

    var body: some View {
        TabView(selection: $tab) {
            MapExploreView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(Tab.map)

            PlacesView()
                .tabItem {
                    Label("Places", systemImage: "mappin.circle.fill")
                }
                .tag(Tab.places)

            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "location.north.line")
                }
                .tag(Tab.trips)

            FriendsFamilyView(pendingInviteFromDeepLink: $pendingFamilyInviteCode)
                .tabItem {
                    Label("Circle", systemImage: "person.2.fill")
                }
                .tag(Tab.circle)

            FitnessDashboardView()
                .tabItem {
                    Label("Move", systemImage: "figure.walk")
                }
                .tag(Tab.move)

            ProfileProgressView()
                .tabItem {
                    Label("You", systemImage: "sparkles")
                }
                .tag(Tab.you)
        }
        .tint(AppTheme.accent)
        .onReceive(NotificationCenter.default.publisher(for: .fmfOpenFamilyJoin)) { notification in
            guard let code = notification.userInfo?["code"] as? String else { return }
            pendingFamilyInviteCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            tab = .circle
        }
    }
}

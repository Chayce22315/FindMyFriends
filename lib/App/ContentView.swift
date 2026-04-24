import SwiftUI

extension Notification.Name {
    /// Switch to the You tab so the user can set the invite backend URL.
    static let fmfOpenYouTabForBackend = Notification.Name("fmf.openYouTab.backend")
}

struct ContentView: View {
    @State private var tab: Tab = .map

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

            FriendsFamilyView()
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
        .onReceive(NotificationCenter.default.publisher(for: .fmfOpenYouTabForBackend)) { _ in
            tab = .you
        }
    }
}

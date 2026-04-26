import SwiftUI

struct ContentView: View {
    @State private var tab: Tab = .map

    private enum Tab: Hashable {
        case map, places, trips, circle, move, music, you
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

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

            MusicTabView()
                .tabItem {
                    Label("Music", systemImage: "music.note")
                }
                .tag(Tab.music)

            ProfileProgressView()
                .tabItem {
                    Label("You", systemImage: "sparkles")
                }
                .tag(Tab.you)
            }
            .tint(AppTheme.accent)
        }
    }
}

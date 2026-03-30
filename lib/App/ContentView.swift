import SwiftUI

struct ContentView: View {
    @State private var tab: Tab = .map

    private enum Tab: Hashable {
        case map, circle, move, you
    }

    var body: some View {
        TabView(selection: $tab) {
            MapExploreView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(Tab.map)

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
    }
}

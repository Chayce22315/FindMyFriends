import SwiftUI

struct ContentView: View {
    @State private var tab: Tab = .map
    @EnvironmentObject private var tracking: TrackingService
    @EnvironmentObject private var liveActivity: LiveActivityManager

    private enum Tab: String, CaseIterable, Hashable {
        case map, places, trips, circle, move, music, you

        var title: String {
            switch self {
            case .map: return "Map"
            case .places: return "Places"
            case .trips: return "Trips"
            case .circle: return "Circle"
            case .move: return "Move"
            case .music: return "Music"
            case .you: return "You"
            }
        }

        var icon: String {
            switch self {
            case .map: return "map.fill"
            case .places: return "mappin.circle.fill"
            case .trips: return "location.north.line"
            case .circle: return "person.2.fill"
            case .move: return "figure.walk"
            case .music: return "music.note"
            case .you: return "person.crop.circle.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            TabView(selection: $tab) {
                MapExploreView()
                    .tag(Tab.map)
                PlacesView()
                    .tag(Tab.places)
                TripsView()
                    .tag(Tab.trips)
                FriendsFamilyView()
                    .tag(Tab.circle)
                FitnessDashboardView()
                    .tag(Tab.move)
                MusicTabView()
                    .tag(Tab.music)
                ProfileProgressView()
                    .tag(Tab.you)
            }
            .tint(AppTheme.accent)
            .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomNavigation
        }
        .overlay(alignment: .top) {
            liveStatusPill
                .padding(.top, 8)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }

    private var bottomNavigation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Tab.allCases, id: \.self) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            tab = item
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .semibold))
                            if tab == item {
                                Text(item.title)
                                    .font(.caption.weight(.bold))
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .foregroundStyle(tab == item ? .white : .secondary)
                        .padding(.horizontal, tab == item ? 14 : 12)
                        .frame(height: 46)
                        .background {
                            Capsule(style: .continuous)
                                .fill(tab == item ? AppTheme.accent.opacity(0.9) : Color.white.opacity(0.07))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
        }
    }

    private var liveStatusPill: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(tracking.isLive ? Color.green : Color.secondary.opacity(0.6))
                .frame(width: 7, height: 7)
            Text(tracking.isLive ? "live location" : "location paused")
                .font(.caption2.weight(.semibold))
            if liveActivity.isRunning {
                Image(systemName: "waveform")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.cyan)
            }
        }
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
        .allowsHitTesting(false)
    }
}

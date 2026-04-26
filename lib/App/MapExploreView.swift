import CoreLocation
import MapKit
import SwiftUI

private struct MapPin: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
    let tint: Color
    let isMe: Bool
}

struct MapExploreView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var tracking: TrackingService
    @EnvironmentObject private var settings: AppSettings

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
    )

    private var pins: [MapPin] {
        var items: [MapPin] = []
        if let c = tracking.coordinate {
            items.append(
                MapPin(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    coordinate: c,
                    title: "You",
                    tint: AppTheme.accent,
                    isMe: true
                )
            )
        }
        for friend in session.friends {
            if let lat = friend.latitude, let lon = friend.longitude {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                items.append(
                    MapPin(
                        id: friend.id,
                        coordinate: coord,
                        title: friend.name,
                        tint: friend.isFamilyMember ? AppTheme.accentSecondary : Color.orange,
                        isMe: false
                    )
                )
            }
        }
        return items
    }

    var body: some View {
        mapWithOverlays
            .onAppear {
                tracking.startLiveTracking(enabled: settings.trackingEnabled, allowBackground: settings.backgroundXPEnabled)
                recenterIfNeeded()
            }
            .onChange(of: tracking.coordinate.map { "\($0.latitude)|\($0.longitude)" } ?? "") { _ in
                recenterIfNeeded()
            }
            .onChange(of: settings.trackingEnabled) { enabled in
                tracking.startLiveTracking(enabled: enabled, allowBackground: settings.backgroundXPEnabled)
            }
            .onChange(of: settings.backgroundXPEnabled) { enabled in
                tracking.startLiveTracking(enabled: settings.trackingEnabled, allowBackground: enabled)
            }
    }

    private var mapWithOverlays: some View {
        Map(coordinateRegion: $region, annotationItems: pins) { pin in
            MapAnnotation(coordinate: pin.coordinate) {
                mapAnnotationView(for: pin)
            }
        }
        .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
        .mapControls {
            MapCompass()
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .top, spacing: 0) {
            mapTopChrome
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            mapBottomChrome
        }
    }

    private var mapTopChrome: some View {
        MapOverlayCard {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Live map")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text(trackingStatusLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                LiveIndicator(isLive: tracking.isLive && settings.trackingEnabled)
            }
        }
        .padding(.horizontal, LayoutMetrics.mapOverlayHorizontalPadding)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var mapBottomChrome: some View {
        MapOverlayCard {
            HStack(spacing: 0) {
                MapFooterStat(title: "On map", value: "\(pins.count)", icon: "mappin.and.ellipse", accent: AppTheme.accent)
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 44)
                MapFooterStat(title: "Friends", value: "\(session.friends.count)", icon: "person.2.fill", accent: AppTheme.accentSecondary)
            }
        }
        .padding(.horizontal, LayoutMetrics.mapOverlayHorizontalPadding)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func mapAnnotationView(for pin: MapPin) -> some View {
        VStack(spacing: 5) {
            ZStack {
                if pin.isMe {
                    Circle()
                        .fill(pin.tint.opacity(0.25))
                        .frame(width: 44, height: 44)
                    Circle()
                        .strokeBorder(.white.opacity(0.35), lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                Image(systemName: pin.isMe ? "location.north.fill" : "mappin.circle.fill")
                    .font(.system(size: pin.isMe ? 22 : 26, weight: .semibold))
                    .foregroundStyle(pin.tint)
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
            }
            Text(pin.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
        }
    }

    private var trackingStatusLabel: String {
        if !settings.trackingEnabled {
            return "Tracking paused — turn on in You"
        }
        switch tracking.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return tracking.isLive ? "Sharing approximate location with family" : "Locating…"
        case .denied, .restricted:
            return "Location off — enable in Settings"
        default:
            return "Location permission needed"
        }
    }

    private func recenterIfNeeded() {
        guard let c = tracking.coordinate else { return }
        withAnimation(.easeInOut) {
            region.center = c
        }
    }
}

// MARK: - Overlay chrome (full-width, no contentMaxWidth letterboxing)

private struct MapOverlayCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(LayoutMetrics.isCompactPhone ? 14 : 16)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.14),
                                        Color.white.opacity(0.05),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
            }
    }
}

private struct LiveIndicator: View {
    var isLive: Bool

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                if isLive {
                    Circle()
                        .fill(Color.green.opacity(0.35))
                        .frame(width: 18, height: 18)
                }
                Circle()
                    .fill(isLive ? Color.green : Color.gray.opacity(0.55))
                    .frame(width: 10, height: 10)
            }
            Text(isLive ? "Live" : "Idle")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isLive ? Color.primary : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
        )
    }
}

private struct MapFooterStat: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 36, alignment: .center)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

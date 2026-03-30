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

    private var isLargePhone: Bool { LayoutMetrics.isLargePhone }

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
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, annotationItems: pins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: pin.isMe ? "location.fill" : "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(pin.tint)
                            .shadow(radius: 4)
                        Text(pin.title)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: isLargePhone ? 16 : 12) {
                GlassCard {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Live map")
                                .font(isLargePhone ? .title.weight(.bold) : .title2.weight(.bold))
                            Text(trackingStatusLabel)
                                .font(isLargePhone ? .body : .subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 12)
                        LiveIndicator(isLive: tracking.isLive && settings.trackingEnabled)
                    }
                }
                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                Spacer()

                GlassCard {
                    HStack(spacing: 20) {
                        MapFooterStat(title: "People on map", value: "\(pins.count)", icon: "mappin.and.ellipse")
                        MapFooterStat(title: "Friends saved", value: "\(session.friends.count)", icon: "person.2.fill")
                    }
                }
                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                .padding(.bottom, isLargePhone ? 18 : 12)
            }
            .padding(.top, isLargePhone ? 16 : 12)
            .contentMaxWidth()
        }
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

    private var trackingStatusLabel: String {
        if !settings.trackingEnabled {
            return "Tracking paused in You"
        }
        switch tracking.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return tracking.isLive ? "Sharing approximate location with family" : "Locating..."
        case .denied, .restricted:
            return "Location off - enable in Settings"
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

private struct LiveIndicator: View {
    var isLive: Bool

    private var isLargePhone: Bool { LayoutMetrics.isLargePhone }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isLive ? Color.green : Color.gray.opacity(0.6))
                .frame(width: isLargePhone ? 12 : 10, height: isLargePhone ? 12 : 10)
            Text(isLive ? "Live" : "Idle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, isLargePhone ? 16 : 14)
        .padding(.vertical, isLargePhone ? 12 : 10)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}

private struct MapFooterStat: View {
    let title: String
    let value: String
    let icon: String

    private var isLargePhone: Bool { LayoutMetrics.isLargePhone }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(isLargePhone ? .title : .title2)
                .foregroundStyle(AppTheme.accent)
                .frame(width: isLargePhone ? 40 : 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(isLargePhone ? .title.weight(.bold) : .title2.weight(.bold))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, annotationItems: pins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: pin.isMe ? "location.fill" : "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(pin.tint)
                            .shadow(radius: 4)
                        Text(pin.title)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 12) {
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Live map")
                                .font(.headline)
                            Text(trackingStatusLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        LiveIndicator(isLive: tracking.isLive && settings.trackingEnabled)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 8)
        }
        .onAppear {
            tracking.requestWhenInUse()
            tracking.startLiveTracking(enabled: settings.trackingEnabled)
            recenterIfNeeded()
        }
        .onChange(of: tracking.coordinate.map { "\($0.latitude)|\($0.longitude)" } ?? "") { _ in
            recenterIfNeeded()
        }
        .onChange(of: settings.trackingEnabled) { enabled in
            tracking.startLiveTracking(enabled: enabled)
        }
    }

    private var trackingStatusLabel: String {
        if !settings.trackingEnabled {
            return "Tracking paused in You"
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

private struct LiveIndicator: View {
    var isLive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isLive ? Color.green : Color.gray.opacity(0.6))
                .frame(width: 8, height: 8)
            Text(isLive ? "Live" : "Idle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}

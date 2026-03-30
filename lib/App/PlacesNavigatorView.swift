import MapKit
import SwiftUI

private struct NavigatorPin: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let tint: Color
    let systemImage: String
}

private struct SearchResult: Identifiable {
    let id = UUID()
    let item: MKMapItem
}

struct PlacesNavigatorView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var tracking: TrackingService

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var isSearching = false
    @State private var results: [SearchResult] = []
    @State private var selectedMode: TransportMode = .driving
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    )

    private var pins: [NavigatorPin] {
        var items: [NavigatorPin] = []
        if let c = tracking.coordinate {
            items.append(
                NavigatorPin(
                    title: "You",
                    subtitle: tracking.travelModeLabel,
                    coordinate: c,
                    tint: AppTheme.accent,
                    systemImage: tracking.travelModeIcon
                )
            )
        }
        for friend in session.friends {
            if let lat = friend.latitude, let lon = friend.longitude {
                items.append(
                    NavigatorPin(
                        title: friend.name,
                        subtitle: friend.isFamilyMember ? "Family" : "Friend",
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        tint: friend.isFamilyMember ? AppTheme.accentSecondary : Color.orange,
                        systemImage: friend.isFamilyMember ? "person.2.fill" : "person.fill"
                    )
                )
            }
        }
        for result in results {
            let item = result.item
            let coord = item.placemark.coordinate
            items.append(
                NavigatorPin(
                    title: item.name ?? "Place",
                    subtitle: item.placemark.title ?? "",
                    coordinate: coord,
                    tint: Color.white,
                    systemImage: "mappin.circle.fill"
                )
            )
        }
        return items
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(coordinateRegion: $region, annotationItems: pins) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: pin.systemImage)
                                .font(.headline)
                                .foregroundStyle(pin.tint)
                                .padding(8)
                                .background(Color.white.opacity(0.9), in: Circle())
                            Text(pin.title)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                TextField("Search places", text: $query)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled(false)
                                Button {
                                    performSearch()
                                } label: {
                                    Image(systemName: isSearching ? "hourglass" : "magnifyingglass")
                                        .font(.title3)
                                }
                                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            HStack(spacing: 8) {
                                ForEach(TransportMode.allCases, id: \.self) { mode in
                                    Button {
                                        selectedMode = mode
                                    } label: {
                                        Label(mode.label, systemImage: mode.icon)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                selectedMode == mode ? AppTheme.accent : Color.white.opacity(0.08),
                                                in: Capsule()
                                            )
                                            .foregroundStyle(selectedMode == mode ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    if !results.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Results")
                                    .font(.headline)
                                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                                    let item = result.item
                                    Button {
                                        openInMaps(item)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name ?? "Place")
                                                    .font(.subheadline.weight(.semibold))
                                                if let title = item.placemark.title {
                                                    Text(title)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            Spacer()
                                            Label("Go", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                                .font(.caption.weight(.semibold))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    if index < results.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                    }

                    Spacer()

                    GlassCard {
                        HStack(spacing: 12) {
                            Image(systemName: tracking.travelModeIcon)
                                .font(.title2)
                                .foregroundStyle(AppTheme.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("You are \(tracking.travelModeLabel.lowercased())")
                                    .font(.subheadline.weight(.semibold))
                                Text("Family pins update in real time on the map.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                    .padding(.bottom, 12)
                }
                .padding(.top, 8)
            }
            .navigationTitle("View & Go")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func performSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            DispatchQueue.main.async {
                let items = response?.mapItems ?? []
                self.results = items.map { SearchResult(item: $0) }
                if let first = items.first {
                    self.region.center = first.placemark.coordinate
                }
                self.isSearching = false
            }
        }
    }

    private func openInMaps(_ item: MKMapItem) {
        let options = [MKLaunchOptionsDirectionsModeKey: selectedMode.directionsMode]
        item.openInMaps(launchOptions: options)
    }
}

private enum TransportMode: CaseIterable {
    case walking
    case cycling
    case driving
    case rideshare
    case flight

    var label: String {
        switch self {
        case .walking: return "Walk"
        case .cycling: return "Cycle"
        case .driving: return "Drive"
        case .rideshare: return "Uber"
        case .flight: return "Fly"
        }
    }

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .driving: return "car.fill"
        case .rideshare: return "car"
        case .flight: return "airplane"
        }
    }

    var directionsMode: String {
        switch self {
        case .walking:
            return MKLaunchOptionsDirectionsModeWalking
        case .cycling:
            return MKLaunchOptionsDirectionsModeDefault
        case .driving, .rideshare:
            return MKLaunchOptionsDirectionsModeDriving
        case .flight:
            return MKLaunchOptionsDirectionsModeDefault
        }
    }
}

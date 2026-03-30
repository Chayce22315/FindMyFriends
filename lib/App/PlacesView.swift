import MapKit
import SwiftUI

private enum PlaceCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case coffee = "Coffee"
    case food = "Food"
    case parks = "Parks"
    case views = "Views"
    case essentials = "Essentials"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "sparkles"
        case .coffee: return "cup.and.saucer.fill"
        case .food: return "fork.knife"
        case .parks: return "leaf.fill"
        case .views: return "binoculars.fill"
        case .essentials: return "bag.fill"
        }
    }
}

private struct Place: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let category: PlaceCategory
    let coordinate: CLLocationCoordinate2D
    let eta: String
    let rating: String
}

struct PlacesView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var tracking: TrackingService
    @EnvironmentObject private var progress: UserProgressStore

    @StateObject private var store = PlacesStore()

    @State private var query = ""
    @State private var selectedCategory: PlaceCategory = .all
    @State private var showNavigator = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    private let places: [Place] = [
        Place(
            name: "Lakeside Brew",
            subtitle: "Cold brew, oat lattes",
            category: .coffee,
            coordinate: CLLocationCoordinate2D(latitude: 37.3319, longitude: -122.0050),
            eta: "6 min",
            rating: "4.8"
        ),
        Place(
            name: "Canyon Green",
            subtitle: "Trail loop and viewpoints",
            category: .parks,
            coordinate: CLLocationCoordinate2D(latitude: 37.3389, longitude: -122.0128),
            eta: "11 min",
            rating: "4.9"
        ),
        Place(
            name: "North Point Market",
            subtitle: "Groceries and ready meals",
            category: .essentials,
            coordinate: CLLocationCoordinate2D(latitude: 37.3331, longitude: -122.0147),
            eta: "4 min",
            rating: "4.6"
        ),
        Place(
            name: "Sunset Table",
            subtitle: "Modern comfort food",
            category: .food,
            coordinate: CLLocationCoordinate2D(latitude: 37.3372, longitude: -122.0011),
            eta: "9 min",
            rating: "4.7"
        ),
        Place(
            name: "Vista Ridge",
            subtitle: "Golden hour lookout",
            category: .views,
            coordinate: CLLocationCoordinate2D(latitude: 37.3287, longitude: -122.0170),
            eta: "12 min",
            rating: "4.9"
        ),
    ]

    private var filteredPlaces: [Place] {
        places.filter { place in
            let matchesCategory = selectedCategory == .all || place.category == selectedCategory
            let matchesQuery = query.isEmpty || place.name.localizedCaseInsensitiveContains(query)
            return matchesCategory && matchesQuery
        }
    }

    private var usesMetric: Bool { Locale.current.usesMetricSystem }

    private var distanceUnitLabel: String { usesMetric ? "km" : "mi" }

    private var distanceValue: String {
        let meters = tracking.distanceMetersToday
        let unitMeters = usesMetric ? 1000.0 : 1609.34
        let value = meters / unitMeters
        return String(format: "%.1f", value)
    }

    private var travelXPPerUnit: Int {
        progress.distanceXPPerUnit(level: progress.level, usesMetric: usesMetric)
    }

    private var travelUnitsAwarded: Int {
        progress.distanceUnitsAwardedToday(usesMetric: usesMetric)
    }

    private var travelXPValue: Int {
        travelUnitsAwarded * travelXPPerUnit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LayoutMetrics.sectionSpacing) {
                        heroHeader

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                TextField("Search places", text: $query)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        HStack {
                                            Image(systemName: "magnifyingglass")
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                    )

                                Map(coordinateRegion: $region, annotationItems: filteredPlaces) { place in
                                    MapAnnotation(coordinate: place.coordinate) {
                                        VStack(spacing: 4) {
                                            Image(systemName: place.category.icon)
                                                .font(.headline)
                                                .foregroundStyle(AppTheme.accent)
                                                .padding(8)
                                                .background(Color.white.opacity(0.9), in: Circle())
                                            Text(place.name)
                                                .font(.caption.weight(.semibold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.ultraThinMaterial, in: Capsule())
                                        }
                                    }
                                }
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                Button {
                                    showNavigator = true
                                } label: {
                                    Label("View & Go", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.body.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.accent)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Travel XP", subtitle: "Earn XP by moving between places.")
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Distance today")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Text("\(distanceValue) \(distanceUnitLabel)")
                                            .font(.title2.weight(.bold))
                                    }
                                    Spacer(minLength: 0)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("XP earned")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Text("+\(travelXPValue)")
                                            .font(.title2.weight(.bold))
                                    }
                                }
                                Text("\(distanceUnitLabel.uppercased()) + \(travelXPPerUnit) XP per \(distanceUnitLabel). Rewards scale +50 XP each level.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Collections", subtitle: "Saved places and curated lists.")
                                ForEach(store.collections) { collection in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(collection.title)
                                            .font(.headline)
                                        Text(collection.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if collection.id != store.collections.last?.id {
                                        Divider()
                                    }
                                }
                                NavigationLink {
                                    SavedPlacesView(store: store)
                                } label: {
                                    Label("Open saved places", systemImage: "bookmark.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Browse")
                                .font(.title2.weight(.bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(PlaceCategory.allCases) { category in
                                        Button {
                                            selectedCategory = category
                                        } label: {
                                            Label(category.rawValue, systemImage: category.icon)
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(
                                                    selectedCategory == category
                                                        ? AppTheme.accent
                                                        : Color.white.opacity(0.08),
                                                    in: Capsule()
                                                )
                                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Featured picks")
                                .font(.title2.weight(.bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(filteredPlaces) { place in
                                        featuredCard(place)
                                    }
                                }
                                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearby now")
                                .font(.title2.weight(.bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                            GlassCard {
                                VStack(spacing: 0) {
                                    ForEach(filteredPlaces) { place in
                                        placeRow(place)
                                        if place.id != filteredPlaces.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                        }
                    }
                    .padding(.vertical, 24)
                    .contentMaxWidth()
                }
            }
            .navigationTitle("Places")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showNavigator) {
            PlacesNavigatorView()
                .environmentObject(session)
                .environmentObject(tracking)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Places")
                .font(.largeTitle.weight(.bold))
            Text("The vibe of Maps, tuned for big screens and fast taps.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }

    private func featuredCard(_ place: Place) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: place.category.icon)
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                    Text("\(place.rating) stars")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(place.name)
                    .font(.headline)
                Text(place.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Label(place.eta, systemImage: "car.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(place.category.rawValue.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, alignment: .leading)
        }
    }

    private func placeRow(_ place: Place) -> some View {
        HStack(spacing: 12) {
            Image(systemName: place.category.icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                Text(place.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(place.eta)
                    .font(.subheadline.weight(.semibold))
                Text("\(place.rating) stars")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

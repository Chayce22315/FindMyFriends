import MapKit
import SwiftUI

struct TripsView: View {
    @StateObject private var store = TripStore()
    @State private var filter: TripFilter = .week
    @State private var selectedTrip: Trip? = Trip.sample.first
    @State private var replayProgress: Double = 0.2
    @State private var isPlaying = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LayoutMetrics.sectionSpacing) {
                        header

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Filters", subtitle: "Quickly scan your travel timeline.")
                                Picker("Trips", selection: $filter) {
                                    ForEach(TripFilter.allCases, id: \.self) { value in
                                        Text(value.rawValue).tag(value)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Replay", subtitle: "Watch a trip on the map.")
                                tripReplay
                                replayControls
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Timeline", subtitle: "Every trip, sorted by time.")
                                ForEach(store.filterTrips(filter)) { trip in
                                    NavigationLink(value: trip) {
                                        HStack(spacing: 12) {
                                            Image(systemName: trip.mode.icon)
                                                .font(.title3)
                                                .foregroundStyle(AppTheme.accent)
                                                .frame(width: 28)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(trip.title)
                                                    .font(.headline)
                                                Text("\(trip.distanceLabel) - \(trip.summary)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    if trip.id != store.filterTrips(filter).last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                    }
                    .padding(.vertical, 24)
                    .contentMaxWidth()
                }
            }
            .navigationTitle("Trips")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trips")
                .font(.largeTitle.weight(.bold))
            Text("Timeline, filters, and map replay.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }

    private var tripReplay: some View {
        let trip = selectedTrip ?? store.trips.first
        return Group {
            if let trip {
                Map(position: .constant(.region(replayRegion(for: trip)))) {
                    if let polyline = replayPolyline(for: trip) {
                        MapPolyline(polyline)
                            .stroke(AppTheme.accent, lineWidth: 4)
                    }
                    if let start = trip.points.first {
                        Annotation("Start", coordinate: start.coordinate) {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    if let end = trip.points.last {
                        Annotation("End", coordinate: end.coordinate) {
                            Image(systemName: "flag.checkered")
                                .foregroundStyle(AppTheme.accentSecondary)
                        }
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Text("No trips yet")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var replayControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    toggleReplay()
                } label: {
                    Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)

                Spacer()
                Text("Progress \(Int(replayProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $replayProgress, in: 0.1...1.0)
                .tint(AppTheme.accent)
        }
    }

    private func toggleReplay() {
        if isPlaying {
            isPlaying = false
            return
        }
        isPlaying = true
        Task {
            while isPlaying && replayProgress < 1.0 {
                try? await Task.sleep(nanoseconds: 220_000_000)
                await MainActor.run {
                    replayProgress = min(1.0, replayProgress + 0.08)
                }
            }
            await MainActor.run {
                isPlaying = false
            }
        }
    }

    private func replayPolyline(for trip: Trip) -> MKPolyline? {
        let count = max(2, Int(Double(trip.points.count) * replayProgress))
        let points = Array(trip.points.prefix(count))
        let coords = points.map { $0.coordinate }
        guard coords.count >= 2 else { return nil }
        return MKPolyline(coordinates: coords, count: coords.count)
    }

    private func replayRegion(for trip: Trip) -> MKCoordinateRegion {
        let coords = trip.points.map { $0.coordinate }
        let latitudes = coords.map { $0.latitude }
        let longitudes = coords.map { $0.longitude }
        let minLat = latitudes.min() ?? 37.3349
        let maxLat = latitudes.max() ?? 37.3349
        let minLon = longitudes.min() ?? -122.0090
        let maxLon = longitudes.max() ?? -122.0090
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max(0.01, (maxLat - minLat) * 1.8), longitudeDelta: max(0.01, (maxLon - minLon) * 1.8))
        return MKCoordinateRegion(center: center, span: span)
    }
}

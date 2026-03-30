import MapKit
import SwiftUI

struct TripDetailView: View {
    let trip: Trip

    @State private var replayProgress: Double = 0.3
    @State private var isPlaying = false
    @State private var speed: ReplaySpeed = .x1

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Route", subtitle: "Replay with speed control.")
                            routeMap
                            replayControls
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Stats", subtitle: "Distance, duration, speed.")
                            HStack(spacing: 16) {
                                statBlock(title: "Distance", value: trip.distanceLabel)
                                statBlock(title: "Duration", value: durationText)
                                statBlock(title: "Avg", value: avgSpeedText)
                            }
                            Text(trip.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    if !trip.stops.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Stops", subtitle: "Moments along the way.")
                                ForEach(trip.stops) { stop in
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(AppTheme.accent)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(stop.name)
                                                .font(.headline)
                                            Text(stop.note)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(stop.arrival.formatted(date: .omitted, time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text("\(stop.durationMinutes) min")
                                                .font(.caption.weight(.semibold))
                                        }
                                    }
                                    if stop.id != trip.stops.last?.id {
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
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trip.title)
                .font(.largeTitle.weight(.bold))
            Text("\(trip.date.formatted(date: .abbreviated, time: .shortened)) - \(trip.mode.label)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }

    private var routeMap: some View {
        Map(position: .constant(.region(replayRegion))) {
            if let polyline = replayPolyline {
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
            ForEach(trip.stops) { stop in
                Annotation(stop.name, coordinate: stop.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(AppTheme.accentSecondary)
                }
            }
        }
        .frame(height: LayoutMetrics.mapCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var replayControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    toggleReplay()
                } label: {
                    Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)

                Picker("Speed", selection: $speed) {
                    ForEach(ReplaySpeed.allCases, id: \.self) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Spacer()
                Text("\(Int(replayProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $replayProgress, in: 0.05...1.0)
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
                let delay = UInt64(220_000_000 / speed.multiplier)
                try? await Task.sleep(nanoseconds: delay)
                await MainActor.run {
                    replayProgress = min(1.0, replayProgress + 0.05 * speed.multiplier)
                }
            }
            await MainActor.run {
                isPlaying = false
            }
        }
    }

    private var durationText: String {
        guard let first = trip.points.first, let last = trip.points.last else { return "--" }
        let seconds = max(0, last.timestamp.timeIntervalSince(first.timestamp))
        let minutes = Int(seconds / 60)
        let hours = minutes / 60
        let remaining = minutes % 60
        return hours > 0 ? "\(hours)h \(remaining)m" : "\(remaining)m"
    }

    private var avgSpeedText: String {
        guard let first = trip.points.first, let last = trip.points.last else { return "--" }
        let hours = max(0.1, last.timestamp.timeIntervalSince(first.timestamp) / 3600)
        let speed = trip.distanceKm / hours
        return String(format: "%.1f km/h", speed)
    }

    private var replayPolyline: MKPolyline? {
        let count = max(2, Int(Double(trip.points.count) * replayProgress))
        let points = Array(trip.points.prefix(count))
        let coords = points.map { $0.coordinate }
        guard coords.count >= 2 else { return nil }
        return MKPolyline(coordinates: coords, count: coords.count)
    }

    private var replayRegion: MKCoordinateRegion {
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

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum ReplaySpeed: Double, CaseIterable {
    case x1 = 1.0
    case x2 = 2.0
    case x4 = 4.0

    var label: String {
        switch self {
        case .x1: return "1x"
        case .x2: return "2x"
        case .x4: return "4x"
        }
    }

    var multiplier: Double { rawValue }
}

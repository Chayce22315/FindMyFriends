import SwiftUI

struct JourneysView: View {
    @StateObject private var store = JourneyStore()

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total distance")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f km", store.totalDistanceKm))
                                .font(.title2.weight(.bold))
                            Text("Auto-generated trip log preview.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    ForEach(store.journeys) { journey in
                        GlassCard {
                            HStack(spacing: 16) {
                                Image(systemName: journey.mode.icon)
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(journey.title)
                                        .font(.headline)
                                    Text(journey.distanceLabel)
                                        .font(.subheadline.weight(.semibold))
                                    Text(journey.highlights)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(journey.mode.label)
                                        .font(.caption.weight(.semibold))
                                    Text(journey.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
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
        .navigationTitle("Journeys")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journeys")
                .font(.largeTitle.weight(.bold))
            Text("A lightweight travel log for your day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }
}

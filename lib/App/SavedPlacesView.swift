import SwiftUI

struct SavedPlacesView: View {
    @ObservedObject var store: PlacesStore

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Collections", subtitle: "Curated groups for quick jumps.")
                            ForEach(store.collections) { collection in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(collection.title)
                                        .font(.headline)
                                    Text(collection.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(collection.places.count) places")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                if collection.id != store.collections.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Saved places", subtitle: "Your personal list.")
                            ForEach(store.savedPlaces) { place in
                                HStack(spacing: 12) {
                                    Image(systemName: place.isFavorite ? "heart.fill" : "mappin.circle")
                                        .foregroundStyle(place.isFavorite ? AppTheme.accentSecondary : AppTheme.accent)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(place.name)
                                            .font(.headline)
                                        Text("\(place.category) • \(place.note)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                if place.id != store.savedPlaces.last?.id {
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
        .navigationTitle("Saved Places")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Places")
                .font(.largeTitle.weight(.bold))
            Text("Collections and favorites in one spot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }
}

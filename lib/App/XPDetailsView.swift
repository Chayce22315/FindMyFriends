import SwiftUI

struct XPDetailsView: View {
    @EnvironmentObject private var progress: UserProgressStore
    @EnvironmentObject private var tracking: TrackingService

    private var usesMetric: Bool { Locale.current.usesMetricSystem }
    private var unitLabel: String { usesMetric ? "km" : "mi" }

    private var xpPerUnit: Int {
        progress.distanceXPPerUnit(level: progress.level, usesMetric: usesMetric)
    }

    private var distanceToday: String {
        TravelDistanceFormatting.displayString(meters: tracking.distanceMetersToday, usesMetric: usesMetric)
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Level info", subtitle: "XP grows as you level up.")
                            Text("Level \(progress.level)")
                                .font(.title2.weight(.bold))
                            Text("XP per \(unitLabel): \(xpPerUnit)")
                                .font(.subheadline.weight(.semibold))
                            Text("Every level adds +50 XP per \(unitLabel).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Today", subtitle: "Distance and rewards.")
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Distance")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text("\(distanceToday) \(unitLabel)")
                                        .font(.title2.weight(.bold))
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("XP earned")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text("\(progress.distanceUnitsAwardedToday(usesMetric: usesMetric) * xpPerUnit)")
                                        .font(.title2.weight(.bold))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "How XP works", subtitle: "Steps plus distance fuel the level up.")
                            Text("Steps: 1 XP per 40 steps (from Health).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Distance: \(xpPerUnit) XP per \(unitLabel) traveled today.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Leveling: more XP required for higher levels.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                }
                .padding(.vertical, 24)
                .contentMaxWidth()
            }
        }
        .navigationTitle("XP Details")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("XP Details")
                .font(.largeTitle.weight(.bold))
            Text("Rewards grow as you move.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }
}

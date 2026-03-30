import SwiftUI

struct SafetyView: View {
    @StateObject private var service = SafetyService()

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    ForEach(service.checks) { check in
                        GlassCard {
                            HStack(spacing: 16) {
                                Image(systemName: check.isActive ? "shield.fill" : "shield")
                                    .font(.title2)
                                    .foregroundStyle(check.isActive ? AppTheme.accentSecondary : .secondary)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(check.title)
                                        .font(.headline)
                                    Text(check.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(check.scheduledAt.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(check.isActive ? "On" : "Off")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(check.isActive ? .green : .secondary)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                    }
                }
                .padding(.vertical, 24)
                .contentMaxWidth()
            }
        }
        .navigationTitle("Safety")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Safety")
                .font(.largeTitle.weight(.bold))
            Text("Smart check-ins and safety pings for your circle.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }
}

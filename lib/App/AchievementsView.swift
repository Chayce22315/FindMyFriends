import SwiftUI

struct AchievementsView: View {
    @StateObject private var service = AchievementsService()

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    ForEach(service.achievements) { achievement in
                        GlassCard {
                            HStack(spacing: 16) {
                                Image(systemName: achievement.icon)
                                    .font(.title2)
                                    .foregroundStyle(achievement.isUnlocked ? AppTheme.accent : .secondary)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(achievement.title)
                                        .font(.headline)
                                    Text(achievement.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    ProgressView(value: achievement.progress, total: achievement.goal)
                                        .tint(AppTheme.accentSecondary)
                                    Text(achievement.isUnlocked ? "Unlocked" : achievement.progressText)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                    }
                }
                .padding(.vertical, 24)
                .contentMaxWidth()
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements")
                .font(.largeTitle.weight(.bold))
            Text("New milestones as you move, explore, and share.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }
}

import SwiftUI

struct ChallengesView: View {
    @StateObject private var service = ChallengeService()
    @EnvironmentObject private var notifications: NotificationManager

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Streaks", subtitle: "Keep the momentum going.")
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text("\(service.streak.current) days")
                                        .font(.title2.weight(.bold))
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Best")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text("\(service.streak.best) days")
                                        .font(.title2.weight(.bold))
                                }
                            }
                            Text("Updated \(service.streak.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Daily challenges", subtitle: "Quick wins for XP.")
                            ForEach(service.challenges) { challenge in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(challenge.title)
                                            .font(.headline)
                                        Spacer()
                                        Text(challenge.isCompleted ? "Done" : challenge.progressText)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(challenge.isCompleted ? .green : .secondary)
                                    }
                                    ProgressView(value: Double(challenge.progress), total: Double(challenge.goal))
                                        .tint(AppTheme.accentSecondary)
                                    Text("Reward \(challenge.rewardXP) XP")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if challenge.id != service.challenges.last?.id {
                                    Divider()
                                }
                            }
                            Button {
                                notifications.scheduleReminder(title: "Daily challenge", body: "Check your new challenge.")
                            } label: {
                                Label("Remind me", systemImage: "bell.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Badges", subtitle: "Milestones you have earned.")
                            ForEach(service.badges) { badge in
                                HStack(spacing: 12) {
                                    Image(systemName: badge.icon)
                                        .foregroundStyle(badge.isUnlocked ? AppTheme.accent : .secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(badge.title)
                                            .font(.headline)
                                        Text(badge.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(badge.isUnlocked ? "Unlocked" : "Locked")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(badge.isUnlocked ? .green : .secondary)
                                }
                                if badge.id != service.badges.last?.id {
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
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Challenges")
                .font(.largeTitle.weight(.bold))
            Text("Badges, streaks, and daily goals.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }
}

import SwiftUI
import UIKit

struct FitnessDashboardView: View {
    @EnvironmentObject private var health: ActivityHealthService
    @EnvironmentObject private var progress: UserProgressStore

    @Environment(\.scenePhase) private var scenePhase

    private var approxDistanceKm: Double {
        Double(health.stepsToday) * 0.000762
    }

    private var stepPercent: CGFloat {
        CGFloat(health.stepsToday) / CGFloat(max(health.stepGoal, 1))
    }

    private var caloriePercent: CGFloat {
        CGFloat(health.activeCalories) / CGFloat(max(health.activeCalorieGoal, 1))
    }

    private var stepsValue: String {
        health.isAuthorized ? "\(health.stepsToday)" : "--"
    }

    private var activeCaloriesValue: String {
        health.isAuthorized ? String(format: "%.0f", health.activeCalories) : "--"
    }

    private var distanceValue: String {
        health.isAuthorized ? String(format: "%.1f", approxDistanceKm) : "--"
    }

    private var healthButtonTitle: String {
        if !health.healthDataAvailable {
            return "Health Unavailable"
        }
        if health.authorizationStatus == .sharingDenied {
            return "Open Health Settings"
        }
        return health.isAuthorized ? "Refresh Health data" : "Connect Apple Health"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LayoutMetrics.sectionSpacing) {
                        heroHeader
                        ringsCard
                        healthCard
                        weekCard
                        xpCard
                        goalsCard
                    }
                    .padding(.vertical, 28)
                    .contentMaxWidth()
                }
            }
            .navigationTitle("Move")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                health.refreshAuthorizationAndData()
                progress.syncXPFromSteps(health.stepsToday)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    health.refreshAuthorizationAndData()
                }
            }
            .onChange(of: health.stepsToday) { _, newValue in
                progress.syncXPFromSteps(newValue)
            }
        }
    }

    // MARK: - Sections (split for Swift type-checker in -O builds)

    @ViewBuilder
    private var ringsCard: some View {
        GlassCard {
            VStack(spacing: 20) {
                Text("Today")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                GeometryReader { geo in
                    let s = min(1.55, max(1.0, geo.size.width / 250))
                    let wide = geo.size.width > 400
                    VStack(spacing: 16) {
                        ActivityRingView(
                            stepProgress: stepPercent,
                            calorieProgress: caloriePercent,
                            scale: s
                        )
                        if wide {
                            HStack(spacing: 24) {
                                stat(title: "Steps", value: stepsValue, caption: "goal \(health.stepGoal)", valueLarge: true)
                                stat(title: "Active", value: activeCaloriesValue, caption: "kcal", valueLarge: true)
                                stat(title: "~Distance", value: distanceValue, caption: "km", valueLarge: true)
                            }
                        } else {
                            HStack(spacing: 28) {
                                stat(title: "Steps", value: stepsValue, caption: "goal \(health.stepGoal)", valueLarge: false)
                                stat(title: "Active", value: activeCaloriesValue, caption: "kcal", valueLarge: false)
                            }
                            stat(title: "~Distance", value: "\(distanceValue) km", caption: "rough from steps", valueLarge: false)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: LayoutMetrics.heroCardHeight)
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    @ViewBuilder
    private var healthCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Fitness", subtitle: "Rings close as you move, XP syncs from your steps.")
                Button {
                    if health.authorizationStatus == .sharingDenied {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } else {
                        health.requestAccess()
                    }
                } label: {
                    Label(healthButtonTitle, systemImage: "heart.fill")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color.pink.opacity(0.9))
                .disabled(!health.healthDataAvailable)

                if !health.healthDataAvailable {
                    Text("Health data is not available on this device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if health.authorizationStatus == .sharingDenied {
                    Text("Health access is off. Enable it in Settings to read steps.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if !health.isAuthorized {
                    Text("Tap Connect, then turn on Steps and Active Energy in the Health sheet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let err = health.lastHealthError, !err.isEmpty {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    @ViewBuilder
    private var weekCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "This week", subtitle: "A quick snapshot, full history lives in Health.")
                HStack(spacing: 12) {
                    weekPill(icon: "flame.fill", title: "Move", value: "\(min(7, max(1, progress.level))) day streak")
                    weekPill(icon: "figure.walk", title: "Steps", value: "Today: \(health.stepsToday)")
                }
                HStack(spacing: 12) {
                    weekPill(icon: "heart.fill", title: "Health", value: health.isAuthorized ? "Connected" : "Not linked")
                    weekPill(icon: "sparkles", title: "Level", value: "\(progress.level)")
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    @ViewBuilder
    private var xpCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "XP from movement", subtitle: "Earn XP as your day fills up.")
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accentSecondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(progress.xp) XP")
                            .font(.title2.weight(.bold))
                        Text("Level \(progress.level) - keep closing rings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    @ViewBuilder
    private var goalsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Goals", subtitle: "Defaults you can tune later.")
                LabeledContent("Step goal") {
                    Text("\(health.stepGoal)")
                        .font(.title3.monospacedDigit().weight(.medium))
                }
                LabeledContent("Active energy goal") {
                    Text("\(Int(health.activeCalorieGoal)) kcal")
                        .font(.title3.monospacedDigit().weight(.medium))
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.largeTitle.weight(.bold))
            Text("Built for big screens, rings, stats, and weekly snapshot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }

    private func weekPill(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func stat(title: String, value: String, caption: String, valueLarge: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: valueLarge ? 34 : 26, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

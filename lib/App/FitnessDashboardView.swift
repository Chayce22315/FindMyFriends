import SwiftUI

struct FitnessDashboardView: View {
    @EnvironmentObject private var health: ActivityHealthService
    @EnvironmentObject private var progress: UserProgressStore
    @EnvironmentObject private var music: MusicService

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    private var approxDistanceKm: Double {
        Double(health.stepsToday) * 0.000762
    }

    private var stepPercent: CGFloat {
        CGFloat(health.stepsToday) / CGFloat(max(health.stepGoal, 1))
    }

    private var caloriePercent: CGFloat {
        CGFloat(health.activeCalories / max(health.activeCalorieGoal, 1))
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

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LayoutMetrics.sectionSpacing) {
                        heroHeader

                        GlassCard {
                            VStack(spacing: 20) {
                                Text("Today")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                GeometryReader { geo in
                                    let s = min(1.7, max(1.15, geo.size.width / 235))
                                    let wide = geo.size.width > 400
                                    VStack(spacing: 20) {
                                        ActivityRingView(
                                            stepProgress: stepPercent,
                                            calorieProgress: caloriePercent,
                                            scale: s
                                        )
                                        if wide {
                                            HStack(spacing: 24) {
                                                stat(
                                                    title: "Steps",
                                                    value: stepsValue,
                                                    caption: "goal \(health.stepGoal)",
                                                    valueLarge: true
                                                )
                                                stat(
                                                    title: "Active",
                                                    value: activeCaloriesValue,
                                                    caption: "kcal",
                                                    valueLarge: true
                                                )
                                                stat(
                                                    title: "~Distance",
                                                    value: distanceValue,
                                                    caption: "km",
                                                    valueLarge: true
                                                )
                                            }
                                        } else {
                                            HStack(spacing: 28) {
                                                stat(
                                                    title: "Steps",
                                                    value: stepsValue,
                                                    caption: "goal \(health.stepGoal)",
                                                    valueLarge: false
                                                )
                                                stat(
                                                    title: "Active",
                                                    value: activeCaloriesValue,
                                                    caption: "kcal",
                                                    valueLarge: false
                                                )
                                            }
                                            stat(
                                                title: "~Distance",
                                                value: "\(distanceValue) km",
                                                caption: "rough from steps",
                                                valueLarge: false
                                            )
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .frame(height: 500)
                            }
                        }
                        .padding(.horizontal)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Fitness", subtitle: "Rings close as you move, XP syncs from your steps.")
                                Button {
                                    health.requestAccess()
                                    health.refreshToday()
                                } label: {
                                    Label(
                                        health.isAuthorized ? "Refresh Health data" : "Connect Apple Health",
                                        systemImage: "heart.fill"
                                    )
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
                                } else if !health.isAuthorized {
                                    Text("Connect Apple Health to pull real steps and active energy.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Music", subtitle: "Connect Apple Music for your move sessions.")
                                Button {
                                    Task {
                                        if music.isAuthorized {
                                            if let url = URL(string: "music://") {
                                                openURL(url)
                                            }
                                        } else {
                                            await music.requestAccess()
                                        }
                                    }
                                } label: {
                                    Label(
                                        music.isAuthorized ? "Open Apple Music" : "Connect Apple Music",
                                        systemImage: "music.note"
                                    )
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)

                                Text("Status: \(music.statusLabel)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)

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
                        .padding(.horizontal)

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
                        .padding(.horizontal)

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
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 28)
                    .contentMaxWidth()
                }
            }
            .navigationTitle("Move")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                health.refreshToday()
                progress.syncXPFromSteps(health.stepsToday)
                music.refreshStatus()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    health.refreshToday()
                }
            }
            .onChange(of: health.stepsToday) { newValue in
                progress.syncXPFromSteps(newValue)
            }
        }
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
        .padding(.horizontal, LayoutMetrics.cardPadding + 4)
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

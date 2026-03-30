import SwiftUI

struct FitnessDashboardView: View {
    @EnvironmentObject private var health: ActivityHealthService
    @EnvironmentObject private var progress: UserProgressStore

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Today")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ActivityRingView(
                                    stepProgress: CGFloat(health.stepsToday) / CGFloat(max(health.stepGoal, 1)),
                                    calorieProgress: CGFloat(health.activeCalories / max(health.activeCalorieGoal, 1))
                                )

                                HStack(spacing: 24) {
                                    stat(title: "Steps", value: "\(health.stepsToday)", caption: "goal \(health.stepGoal)")
                                    stat(title: "Active", value: String(format: "%.0f", health.activeCalories), caption: "kcal")
                                }
                            }
                        }
                        .padding(.horizontal)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Fitness", subtitle: "Rings close as you move — XP syncs from your steps.")
                                Button {
                                    health.requestAccess()
                                    health.refreshToday()
                                } label: {
                                    Label(
                                        health.isAuthorized ? "Refresh Health data" : "Connect Apple Health",
                                        systemImage: "heart.fill"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.pink.opacity(0.9))
                                .disabled(!health.healthDataAvailable)

                                if !health.healthDataAvailable {
                                    Text("Health data is not available on this device.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "XP from movement", subtitle: "Earn XP as your day fills up.")
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(AppTheme.accentSecondary)
                                    Text("\(progress.xp) XP · Level \(progress.level)")
                                        .font(.headline)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Move")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                health.requestAccess()
                health.refreshToday()
                progress.syncXPFromSteps(health.stepsToday)
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

    private func stat(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

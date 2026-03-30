import SwiftUI

struct ProfileProgressView: View {
    @EnvironmentObject private var progress: UserProgressStore
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifications: NotificationManager
    @EnvironmentObject private var tracking: TrackingService

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Level \(progress.level)")
                                            .font(.largeTitle.weight(.bold))
                                        Text("\(progress.xp) XP")
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppTheme.accent, AppTheme.glow],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 72, height: 72)
                                        Text("\(progress.level)")
                                            .font(.title.weight(.heavy))
                                            .foregroundStyle(.white)
                                    }
                                }

                                let p = min(
                                    1,
                                    max(
                                        0,
                                        Double(progress.xpIntoLevel) / Double(max(progress.xpForNextLevel, 1))
                                    )
                                )
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Next level")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(progress.xpIntoLevel) / \(progress.xpForNextLevel) XP")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    ProgressView(value: p)
                                        .tint(AppTheme.accent)
                                }
                            }
                        }
                        .padding(.horizontal)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Tracking", subtitle: "Share your location on the map with your family.")
                                Toggle(isOn: $settings.trackingEnabled) {
                                    Label("Live location", systemImage: "location.fill")
                                }
                                .tint(AppTheme.accent)
                                .onChange(of: settings.trackingEnabled) { enabled in
                                    if enabled {
                                        tracking.requestWhenInUse()
                                    }
                                    tracking.startLiveTracking(enabled: enabled)
                                }
                            }
                        }
                        .padding(.horizontal)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Notifications", subtitle: "Level-ups and gentle nudges.")
                                Toggle(isOn: $settings.notificationsEnabled) {
                                    Label("Alerts & level-ups", systemImage: "bell.badge.fill")
                                }
                                .tint(AppTheme.accent)

                                Button {
                                    notifications.requestPermission()
                                } label: {
                                    Label("Manage notification permission", systemImage: "gear")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)

                                Text(statusText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "Tips", subtitle: "Modern, private, and built for real life.")
                                Label("Family is required for real-life friends", systemImage: "person.3.fill")
                                Label("Maps + tracking respect your toggles", systemImage: "map.fill")
                                Label("XP grows with your steps (Health)", systemImage: "figure.walk")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                notifications.refreshStatus()
                if settings.trackingEnabled {
                    tracking.requestWhenInUse()
                    tracking.startLiveTracking(enabled: true)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didLevelUp)) { note in
                guard settings.notificationsEnabled else { return }
                guard notifications.authorizationStatus == .authorized else { return }
                if let level = note.object as? Int {
                    notifications.scheduleLevelUp(level: level)
                }
            }
        }
    }

    private var statusText: String {
        switch notifications.authorizationStatus {
        case .authorized:
            return "Notifications are on."
        case .denied:
            return "Notifications are off in Settings — enable them for level-up alerts."
        case .notDetermined:
            return "We will ask before sending anything."
        case .provisional:
            return "Quiet notifications are enabled."
        case .ephemeral:
            return "Temporary authorization."
        @unknown default:
            return ""
        }
    }
}

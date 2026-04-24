import SwiftUI

struct ProfileProgressView: View {
    @EnvironmentObject private var progress: UserProgressStore
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifications: NotificationManager
    @EnvironmentObject private var tracking: TrackingService
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var music: MusicService
    @EnvironmentObject private var liveActivity: LiveActivityManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LayoutMetrics.sectionSpacing) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Profile")
                                .font(.largeTitle.weight(.bold))
                            Text("Level, privacy, and how you show up to your circle.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack(alignment: .center, spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Level \(progress.level)")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                        Text("\(progress.xp) XP total")
                                            .font(.title3)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 12)
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppTheme.accent, AppTheme.glow],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 96, height: 96)
                                        Text("\(progress.level)")
                                            .font(.system(size: 40, weight: .heavy, design: .rounded))
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
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Next level")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(progress.xpIntoLevel) / \(progress.xpForNextLevel) XP")
                                            .font(.subheadline.monospacedDigit().weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    ProgressView(value: p)
                                        .scaleEffect(x: 1, y: 1.35, anchor: .center)
                                        .tint(AppTheme.accent)
                                }
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Highlights", subtitle: "Quick stats from your circle.")
                                HStack(spacing: 12) {
                                    highlightTile(icon: "person.2.fill", title: "Friends", value: "\(session.friends.count)")
                                    highlightTile(icon: "figure.2.and.child.holdinghands", title: "Family", value: session.hasFamily ? "On" : "Off")
                                }
                                HStack(spacing: 12) {
                                    highlightTile(icon: "location.fill", title: "Live map", value: settings.trackingEnabled ? "On" : "Paused")
                                    highlightTile(icon: "heart.fill", title: "Health", value: "Move tab")
                                }
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Tracking", subtitle: "Share your location on the map with your family.")
                                Toggle(isOn: $settings.trackingEnabled) {
                                    Label("Live location", systemImage: "location.fill")
                                        .font(.body.weight(.medium))
                                }
                                .tint(AppTheme.accent)
                                .onChange(of: settings.trackingEnabled) { enabled in
                                    tracking.startLiveTracking(enabled: enabled, allowBackground: settings.backgroundXPEnabled)
                                }

                                Toggle(isOn: $settings.backgroundXPEnabled) {
                                    Label("Background XP tracking", systemImage: "figure.walk.circle")
                                        .font(.body.weight(.medium))
                                }
                                .tint(AppTheme.accent)
                                .onChange(of: settings.backgroundXPEnabled) { enabled in
                                    tracking.startLiveTracking(enabled: settings.trackingEnabled, allowBackground: enabled)
                                }
                                Text("Track miles in the background to earn XP even when the app is closed.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Notifications", subtitle: "Level-ups and gentle nudges.")
                                Toggle(isOn: $settings.notificationsEnabled) {
                                    Label("Alerts & level-ups", systemImage: "bell.badge.fill")
                                        .font(.body.weight(.medium))
                                }
                                .tint(AppTheme.accent)

                                Button {
                                    notifications.requestPermission()
                                } label: {
                                    Label("Manage notification permission", systemImage: "gear")
                                        .font(.body.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)

                                Text(statusText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Invite server", subtitle: "The app ships with a default public URL; change it only if you host your own backend.")
                                TextField("https://…onrender.com", text: $settings.backendBaseURL)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                                Text("Share uses the real join link from the server (https), not localhost.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Appearance", subtitle: "Switch on Liquid Glass styling.")
                                Toggle(isOn: $settings.liquidGlassEnabled) {
                                    Label("Liquid Glass", systemImage: "drop.fill")
                                        .font(.body.weight(.medium))
                                }
                                .tint(AppTheme.accent)
                                Text("Adds glossy highlights and a fluid look across cards.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Dynamic Island", subtitle: "Live Activities for movement status.")
                                HStack(spacing: 12) {
                                    Image(systemName: liveActivity.isRunning ? "dot.radiowaves.left.and.right" : "moon.zzz")
                                        .font(.title3)
                                        .foregroundStyle(liveActivity.isRunning ? AppTheme.accent : .secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(liveActivity.isRunning ? "Live Activity running" : "Live Activity idle")
                                            .font(.headline)
                                        Text(liveActivity.statusLabel)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }

                                if liveActivity.isRunning {
                                    Button {
                                        Task { await liveActivity.end() }
                                    } label: {
                                        Label("End Live Activity", systemImage: "stop.circle")
                                            .font(.body.weight(.semibold))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)
                                }

                                Text("Starts automatically when Live location is on.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "More to explore", subtitle: "Extra features so the app feels fully loaded.")
                                NavigationLink {
                                    AchievementsView()
                                } label: {
                                    MoreLinkRow(icon: "trophy.fill", title: "Achievements", subtitle: "Unlock travel milestones.")
                                }
                                .buttonStyle(.plain)

                                Divider()

                                NavigationLink {
                                    JourneysView()
                                } label: {
                                    MoreLinkRow(icon: "location.north.line", title: "Journeys", subtitle: "A trip history snapshot.")
                                }
                                .buttonStyle(.plain)

                                Divider()

                                NavigationLink {
                                    SavedPlacesView(store: PlacesStore())
                                } label: {
                                    MoreLinkRow(icon: "bookmark.fill", title: "Saved Places", subtitle: "Collections and favorites.")
                                }
                                .buttonStyle(.plain)

                                Divider()

                                NavigationLink {
                                    SafetyView()
                                } label: {
                                    MoreLinkRow(icon: "shield.fill", title: "Safety", subtitle: "Automated check-ins.")
                                }
                                .buttonStyle(.plain)

                                Divider()

                                NavigationLink {
                                    SocialFeedView()
                                } label: {
                                    MoreLinkRow(icon: "person.2.wave.2", title: "Social Feed", subtitle: "Family check-ins and reactions.")
                                }
                                .buttonStyle(.plain)

                                Divider()

                                NavigationLink {
                                    ChallengesView()
                                } label: {
                                    MoreLinkRow(icon: "checkmark.seal.fill", title: "Challenges", subtitle: "Badges, streaks, daily goals.")
                                }
                                .buttonStyle(.plain)

                                Divider()

                                NavigationLink {
                                    XPDetailsView()
                                } label: {
                                    MoreLinkRow(icon: "sparkles", title: "XP Details", subtitle: "Level and reward math.")
                                }
                                .buttonStyle(.plain)

                                if music.isAuthorized {
                                    Divider()

                                    NavigationLink {
                                        MusicInsightsView()
                                    } label: {
                                        MoreLinkRow(icon: "music.note.list", title: "Music Insights", subtitle: "Recently played and recommendations.")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Tips", subtitle: "Built for modern iPhones, not a tiny widget.")
                                tipRow(icon: "person.3.fill", text: "Family unlocks real-life friends and invites.")
                                tipRow(icon: "map.fill", text: "Maps and tracking follow your toggles here.")
                                tipRow(icon: "figure.walk", text: "XP grows when you move, see Move for rings.")
                                tipRow(icon: "lock.shield.fill", text: "Contacts are only used when you tap to add.")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                        VStack(spacing: 6) {
                            Text("Find My Friends")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                Text("Version \(version)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 28)
                    .contentMaxWidth()
                }
            }
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                notifications.refreshStatus()
                music.refreshStatus()
                if settings.trackingEnabled {
                    tracking.startLiveTracking(enabled: true, allowBackground: settings.backgroundXPEnabled)
                }
            }
        }
    }

    private func highlightTile(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func tipRow(icon: String, text: String) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accentSecondary)
        }
        .labelStyle(.titleAndIcon)
    }

    private var statusText: String {
        switch notifications.authorizationStatus {
        case .authorized:
            return "Notifications are on."
        case .denied:
            return "Notifications are off in Settings, enable them for level-up alerts."
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

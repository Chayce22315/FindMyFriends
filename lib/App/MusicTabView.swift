import MusicKit
import SwiftUI
import UIKit

/// Root tab: Apple Music connection, live now playing + history, catalog, library, and insights.
struct MusicTabView: View {
    @EnvironmentObject private var music: MusicService
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LayoutMetrics.sectionSpacing) {
                        header
                        connectCard
                        livePlaybackCard
                        if music.isAuthorized {
                            catalogRecentsCard
                        }
                        musicVibesCard
                        if music.isAuthorized {
                            libraryMusicCard
                        }
                        insightsLibrarySection(
                            title: "Recently played",
                            subtitle: "From your on-device library (when allowed)."
                        ) {
                            if music.recentlyPlayed.isEmpty {
                                insightsEmptyState
                            } else {
                                ForEach(music.recentlyPlayed) { track in
                                    MusicTabTrackRow(track: track)
                                    if track.id != music.recentlyPlayed.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                        insightsLibrarySection(
                            title: "Recommended",
                            subtitle: "Picked from your library play patterns."
                        ) {
                            if music.recommendations.isEmpty {
                                insightsEmptyState
                            } else {
                                ForEach(music.recommendations) { track in
                                    MusicTabTrackRow(track: track)
                                    if track.id != music.recommendations.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                        insightsLibrarySection(
                            title: "Top artists",
                            subtitle: "Most played in your library."
                        ) {
                            if music.topArtists.isEmpty {
                                insightsEmptyState
                            } else {
                                ForEach(music.topArtists) { artist in
                                    MusicTabArtistRow(artist: artist)
                                    if artist.id != music.topArtists.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 28)
                    .contentMaxWidth()
                }
            }
            .navigationTitle("Music")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                music.refreshStatus()
                music.loadInsightsIfNeeded()
                music.beginLivePlaybackUpdates()
            }
            .onDisappear {
                music.endLivePlaybackUpdates()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    music.refreshStatus()
                    music.loadInsightsIfNeeded()
                    music.refreshLivePlaybackFromPlayers()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Soundtrack")
                .font(.largeTitle.weight(.bold))
            Text("Live playback, history, and library — without crowding Move.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }

    private var connectCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Connect", subtitle: "Apple Music and your on-device library.")
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
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppTheme.accent)

                Text("Apple Music: \(music.statusLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Media Library: \(music.libraryStatusLabel)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 12) {
                    Button {
                        Task { await music.forceReloadMusicInsights() }
                    } label: {
                        Label("Refresh catalog & library", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        music.clearLivePlaybackHistory()
                    } label: {
                        Label("Clear history", systemImage: "trash")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }

                if let msg = music.playbackMessage, !msg.isEmpty {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    private var livePlaybackCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Live playback",
                    subtitle: "Updates from the Music app. Previous tracks accumulate in the list below (newest first)."
                )
                if let now = music.liveNowPlaying {
                    Text("Now playing")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    livePlaybackLineRow(now, icon: "waveform")
                } else {
                    Text("Nothing playing — start music in the Music app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !music.livePlaybackHistory.isEmpty {
                    Text("Previously played (this session)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                    ForEach(music.livePlaybackHistory) { line in
                        livePlaybackLineRow(line, icon: "backward.end.fill")
                        if line.id != music.livePlaybackHistory.last?.id {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    private var catalogRecentsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Apple Music (catalog)",
                    subtitle: "Cloud recent plays — tap Refresh above to update."
                )
                if music.appleMusicRecentSongs.isEmpty {
                    Text("No catalog recents yet, or MusicKit could not load them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(music.appleMusicRecentSongs) { song in
                        catalogSongRow(song)
                    }
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    private var musicVibesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Music Vibes", subtitle: "Quick picks for the next session.")
                if music.isAuthorized, !music.recommendations.isEmpty {
                    ForEach(Array(music.recommendations.prefix(2))) { track in
                        HStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .font(.title3)
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title)
                                    .font(.headline)
                                Text("\(track.artist) - \(track.duration)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(track.hapticsAllowed ? "Haptics On" : "Haptics Off")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(track.hapticsAllowed ? AppTheme.accentSecondary : .secondary)
                        }
                    }
                } else {
                    Text("Connect Apple Music to unlock personalized picks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    private var libraryMusicCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Your library (on device)",
                    subtitle: music.isLibraryAuthorized
                        ? "Downloaded or synced songs — tap to play."
                        : "Allow Media Library in Settings to see songs stored on this iPhone."
                )
                if music.isLibraryAuthorized {
                    libraryRecentSection
                    libraryArtistsSection
                }
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    private var libraryRecentSection: some View {
        Group {
            if !music.recentlyPlayed.isEmpty {
                Text("Recently played (library)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(Array(music.recentlyPlayed.prefix(6))) { track in
                    Button {
                        music.playLibraryTrack(track)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(track.artist)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.accent)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var libraryArtistsSection: some View {
        Group {
            if !music.topArtists.isEmpty {
                Text("Artists in your library")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                ForEach(Array(music.topArtists.prefix(6))) { artist in
                    Button {
                        music.playLibraryArtist(artist)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(artist.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Top: \(artist.topSong) · \(artist.plays) plays in library")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "shuffle.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.accentSecondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func catalogSongRow(_ song: Song) -> some View {
        Button {
            Task { await music.playAppleMusicSong(song) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if let a = song.artists?.first?.name {
                        Text(a)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func livePlaybackLineRow(_ line: LivePlaybackLine, icon: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(line.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
        }
    }

    private var insightsEmptyState: some View {
        Text(music.isLibraryAuthorized ? "No data yet for this section." : "Allow Media Library access for library-based lists.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
    }

    private func insightsLibrarySection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title, subtitle: subtitle)
                content()
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }
}

private struct MusicTabTrackRow: View {
    let track: MusicTrack

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                Text("\(track.artist) - \(track.duration)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(track.mood)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.accentSecondary)
                Label(track.hapticsAllowed ? "Haptics On" : "Haptics Off", systemImage: track.hapticsAllowed ? "waveform.path" : "waveform.path.badge.minus")
                    .font(.caption2)
                    .foregroundStyle(track.hapticsAllowed ? .secondary : .tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MusicTabArtistRow: View {
    let artist: MusicArtist

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.square.filled.and.at.rectangle")
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.headline)
                Text("Top song: \(artist.topSong)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(artist.plays) plays")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI

struct MusicInsightsView: View {
    @EnvironmentObject private var music: MusicService

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    insightsSection(title: "Recently played", subtitle: "Your latest listens.") {
                        if music.recentlyPlayed.isEmpty {
                            emptyState
                        } else {
                            ForEach(music.recentlyPlayed) { track in
                                MusicTrackRow(track: track)
                                if track.id != music.recentlyPlayed.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    insightsSection(title: "Recommended", subtitle: "Picked for your movement vibe.") {
                        if music.recommendations.isEmpty {
                            emptyState
                        } else {
                            ForEach(music.recommendations) { track in
                                MusicTrackRow(track: track)
                                if track.id != music.recommendations.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    insightsSection(title: "Top artists", subtitle: "Most played this month.") {
                        if music.topArtists.isEmpty {
                            emptyState
                        } else {
                            ForEach(music.topArtists) { artist in
                                MusicArtistRow(artist: artist)
                                if artist.id != music.topArtists.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 24)
                .contentMaxWidth()
            }
        }
        .navigationTitle("Music")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            music.loadInsightsIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Music Insights")
                .font(.largeTitle.weight(.bold))
            Text("Recently played, recommended, and your top artists.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }

    private var emptyState: some View {
        Text(music.isLibraryAuthorized ? "No recent plays yet. Start a session to populate this list." : "Allow Media Library access for real music data.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
    }

    private func insightsSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title, subtitle: subtitle)
                content()
            }
        }
        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }
}

private struct MusicTrackRow: View {
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

private struct MusicArtistRow: View {
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

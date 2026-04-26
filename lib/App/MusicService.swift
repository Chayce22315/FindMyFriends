import Foundation
import MediaPlayer
import MusicKit

struct MusicTrack: Identifiable, Hashable, Codable {
    let id: UUID
    let libraryPersistentID: UInt64?
    let title: String
    let artist: String
    let duration: String
    let hapticsAllowed: Bool
    let mood: String
}

struct MusicArtist: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let plays: Int
    let topSong: String
}

final class MusicService: ObservableObject {
    @Published private(set) var status: MusicAuthorization.Status = MusicAuthorization.currentStatus
    @Published private(set) var libraryStatus: MPMediaLibraryAuthorizationStatus = MPMediaLibrary.authorizationStatus()
    @Published private(set) var recentlyPlayed: [MusicTrack] = []
    @Published private(set) var recommendations: [MusicTrack] = []
    @Published private(set) var topArtists: [MusicArtist] = []
    /// From Apple Music subscription / cloud (MusicKit), not the downloaded-library query.
    @Published private(set) var appleMusicRecentSongs: [Song] = []
    @Published private(set) var playbackMessage: String?

    private var didLoadLibraryInsights = false
    private var didLoadCatalogRecent = false

    var isAuthorized: Bool { status == .authorized }
    var isLibraryAuthorized: Bool { libraryStatus == .authorized }

    func refreshStatus() {
        status = MusicAuthorization.currentStatus
        libraryStatus = MPMediaLibrary.authorizationStatus()
    }

    func requestAccess() async {
        let newStatus = await MusicAuthorization.request()
        let newLibraryStatus = await requestLibraryAccess()
        await MainActor.run {
            status = newStatus
            libraryStatus = newLibraryStatus
            didLoadLibraryInsights = false
            didLoadCatalogRecent = false
        }
        await reloadAllInsights()
    }

    /// Call after connect or when Move tab appears.
    func reloadAllInsights() async {
        await MainActor.run {
            didLoadLibraryInsights = false
            didLoadCatalogRecent = false
        }
        await loadCatalogRecentlyPlayedIfNeeded()
        await MainActor.run {
            loadLibraryInsightsIfNeeded()
        }
    }

    func loadLibraryInsightsIfNeeded() {
        guard isAuthorized else { return }
        guard !didLoadLibraryInsights else { return }
        didLoadLibraryInsights = true
        if isLibraryAuthorized {
            loadLibraryInsightsFromMediaPlayer()
        } else {
            loadMockInsights()
        }
    }

    private func loadCatalogRecentlyPlayedIfNeeded() async {
        guard isAuthorized else { return }
        guard !didLoadCatalogRecent else { return }
        didLoadCatalogRecent = true
        do {
            let request = MusicRecentlyPlayedRequest<Song>()
            let response = try await request.response()
            await MainActor.run {
                appleMusicRecentSongs = Array(response.items.prefix(20))
                if appleMusicRecentSongs.isEmpty {
                    playbackMessage = "No Apple Music plays yet — stream a song in Music, then tap Refresh."
                }
            }
        } catch {
            await MainActor.run {
                appleMusicRecentSongs = []
                playbackMessage = error.localizedDescription
            }
        }
    }

    /// Play a catalog `Song` from Apple Music (needs subscription + MusicKit auth).
    func playAppleMusicSong(_ song: Song) async {
        await MainActor.run { playbackMessage = nil }
        guard isAuthorized else {
            await MainActor.run { playbackMessage = "Connect Apple Music first." }
            return
        }
        do {
            let player = SystemMusicPlayer.shared
            player.queue = [song]
            try await player.play()
            await MainActor.run { playbackMessage = "Playing \(song.title)" }
        } catch {
            await MainActor.run { playbackMessage = error.localizedDescription }
        }
    }

    private func requestLibraryAccess() async -> MPMediaLibraryAuthorizationStatus {
        await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func loadLibraryInsightsFromMediaPlayer() {
        DispatchQueue.global(qos: .userInitiated).async {
            let songs = MPMediaQuery.songs().items ?? []
            let recent = songs
                .filter { $0.lastPlayedDate != nil }
                .sorted { ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast) }
            let recentSet = Set(recent.prefix(30).map { $0.persistentID })
            let byPlayCount = songs.sorted { $0.playCount > $1.playCount }
            let recommended = byPlayCount.filter { !recentSet.contains($0.persistentID) }

            let recentTracks = recent.prefix(8).map(Self.mapTrack)
            let recommendedTracks = recommended.prefix(8).map(Self.mapTrack)
            let topArtists = Self.buildTopArtists(from: songs).prefix(6).map { $0 }

            DispatchQueue.main.async {
                self.recentlyPlayed = recentTracks
                self.recommendations = recommendedTracks
                self.topArtists = topArtists
            }
        }
    }

    private static func buildTopArtists(from songs: [MPMediaItem]) -> [MusicArtist] {
        var buckets: [String: (plays: Int, topSong: String)] = [:]
        for song in songs {
            let name = song.artist ?? "Unknown Artist"
            let plays = song.playCount
            let current = buckets[name] ?? (0, song.title ?? "Unknown Song")
            let newPlays = current.plays + plays
            let topSong = current.plays >= plays ? current.topSong : (song.title ?? current.topSong)
            buckets[name] = (newPlays, topSong)
        }
        return buckets
            .map { key, value in
                MusicArtist(id: UUID(), name: key, plays: value.plays, topSong: value.topSong)
            }
            .sorted { $0.plays > $1.plays }
    }

    private static func mapTrack(_ item: MPMediaItem) -> MusicTrack {
        let duration = item.playbackDuration
        let minutes = Int(duration / 60)
        let seconds = Int(duration) % 60
        let durationLabel = String(format: "%d:%02d", minutes, seconds)
        let hapticsAllowed = duration > 60 && duration < 600
        return MusicTrack(
            id: UUID(),
            libraryPersistentID: item.persistentID,
            title: item.title ?? "Unknown Track",
            artist: item.artist ?? "Unknown Artist",
            duration: durationLabel,
            hapticsAllowed: hapticsAllowed,
            mood: hapticsAllowed ? "Energy" : "Chill"
        )
    }

    func playLibraryTrack(_ track: MusicTrack) {
        playbackMessage = nil
        guard isAuthorized else {
            playbackMessage = "Connect Apple Music first."
            return
        }
        guard isLibraryAuthorized else {
            playbackMessage = "Allow Media Library in Settings to play downloaded library songs."
            return
        }
        guard let pid = track.libraryPersistentID else {
            playbackMessage = "This row is a preview — use real library data to play."
            return
        }
        let pred = MPMediaPropertyPredicate(value: NSNumber(value: pid), forProperty: MPMediaItemPropertyPersistentID)
        let query = MPMediaQuery()
        query.addFilterPredicate(pred)
        guard let item = query.items?.first else {
            playbackMessage = "Could not find that song in your library."
            return
        }
        let player = MPMusicPlayerController.systemMusicPlayer
        player.setQueue(with: MPMediaItemCollection(items: [item]))
        player.play()
        playbackMessage = "Playing \(track.title)"
    }

    func playLibraryArtist(_ artist: MusicArtist) {
        playbackMessage = nil
        guard isAuthorized, isLibraryAuthorized else {
            playbackMessage = "Connect Apple Music and allow Media Library access."
            return
        }
        let name = artist.name
        let pred = MPMediaPropertyPredicate(value: name, forProperty: MPMediaItemPropertyArtist, comparisonType: .equalTo)
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(pred)
        let items = (query.items ?? []).sorted { $0.playCount > $1.playCount }
        let slice = Array(items.prefix(24))
        guard !slice.isEmpty else {
            playbackMessage = "No songs for \(name) in this library."
            return
        }
        let player = MPMusicPlayerController.systemMusicPlayer
        player.setQueue(with: MPMediaItemCollection(items: slice))
        player.shuffleMode = .songs
        player.play()
        playbackMessage = "Playing \(artist.name)"
    }

    private func loadMockInsights() {
        recentlyPlayed = [
            MusicTrack(
                id: UUID(),
                libraryPersistentID: nil,
                title: "Solar Run",
                artist: "Nina Vale",
                duration: "3:42",
                hapticsAllowed: true,
                mood: "Focus"
            ),
            MusicTrack(
                id: UUID(),
                libraryPersistentID: nil,
                title: "Night Ride",
                artist: "Atlas Drive",
                duration: "4:18",
                hapticsAllowed: false,
                mood: "Energy"
            ),
            MusicTrack(
                id: UUID(),
                libraryPersistentID: nil,
                title: "Coastline",
                artist: "Eden Park",
                duration: "2:59",
                hapticsAllowed: true,
                mood: "Chill"
            )
        ]

        recommendations = [
            MusicTrack(
                id: UUID(),
                libraryPersistentID: nil,
                title: "Pulse Runner",
                artist: "Mono Lake",
                duration: "3:12",
                hapticsAllowed: true,
                mood: "Sprint"
            ),
            MusicTrack(
                id: UUID(),
                libraryPersistentID: nil,
                title: "Clouds Over",
                artist: "Vera Stone",
                duration: "3:55",
                hapticsAllowed: false,
                mood: "Recovery"
            ),
            MusicTrack(
                id: UUID(),
                libraryPersistentID: nil,
                title: "Golden Hours",
                artist: "Lumen",
                duration: "4:06",
                hapticsAllowed: true,
                mood: "Warmup"
            )
        ]

        topArtists = [
            MusicArtist(id: UUID(), name: "Atlas Drive", plays: 42, topSong: "Night Ride"),
            MusicArtist(id: UUID(), name: "Nina Vale", plays: 36, topSong: "Solar Run"),
            MusicArtist(id: UUID(), name: "Lumen", plays: 29, topSong: "Golden Hours")
        ]
    }

    var statusLabel: String {
        switch status {
        case .authorized:
            return "Connected"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not connected"
        @unknown default:
            return "Unknown"
        }
    }

    var libraryStatusLabel: String {
        switch libraryStatus {
        case .authorized:
            return "Library allowed"
        case .denied:
            return "Library denied"
        case .notDetermined:
            return "Library not asked"
        case .restricted:
            return "Library restricted"
        @unknown default:
            return "Library unknown"
        }
    }

    /// Backwards-compatible entry for views that only refreshed library insights before.
    func loadInsightsIfNeeded() {
        Task { await reloadAllInsights() }
    }
}

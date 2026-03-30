import Foundation
import MediaPlayer
import MusicKit

struct MusicTrack: Identifiable, Hashable, Codable {
    let id: UUID
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

    private var didLoadInsights = false

    var isAuthorized: Bool { status == .authorized }
    var isLibraryAuthorized: Bool { libraryStatus == .authorized }

    func refreshStatus() {
        status = MusicAuthorization.currentStatus
        libraryStatus = MPMediaLibrary.authorizationStatus()
        didLoadInsights = false
        loadInsightsIfNeeded()
    }

    func requestAccess() async {
        let newStatus = await MusicAuthorization.request()
        let newLibraryStatus = await requestLibraryAccess()
        await MainActor.run {
            status = newStatus
            libraryStatus = newLibraryStatus
            didLoadInsights = false
            loadInsightsIfNeeded()
        }
    }

    func loadInsightsIfNeeded() {
        guard isAuthorized else { return }
        guard !didLoadInsights else { return }
        didLoadInsights = true
        if isLibraryAuthorized {
            loadLibraryInsights()
        } else {
            loadMockInsights()
        }
    }

    private func requestLibraryAccess() async -> MPMediaLibraryAuthorizationStatus {
        await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func loadLibraryInsights() {
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
            title: item.title ?? "Unknown Track",
            artist: item.artist ?? "Unknown Artist",
            duration: durationLabel,
            hapticsAllowed: hapticsAllowed,
            mood: hapticsAllowed ? "Energy" : "Chill"
        )
    }

    private func loadMockInsights() {
        recentlyPlayed = [
            MusicTrack(
                id: UUID(),
                title: "Solar Run",
                artist: "Nina Vale",
                duration: "3:42",
                hapticsAllowed: true,
                mood: "Focus"
            ),
            MusicTrack(
                id: UUID(),
                title: "Night Ride",
                artist: "Atlas Drive",
                duration: "4:18",
                hapticsAllowed: false,
                mood: "Energy"
            ),
            MusicTrack(
                id: UUID(),
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
                title: "Pulse Runner",
                artist: "Mono Lake",
                duration: "3:12",
                hapticsAllowed: true,
                mood: "Sprint"
            ),
            MusicTrack(
                id: UUID(),
                title: "Clouds Over",
                artist: "Vera Stone",
                duration: "3:55",
                hapticsAllowed: false,
                mood: "Recovery"
            ),
            MusicTrack(
                id: UUID(),
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
}

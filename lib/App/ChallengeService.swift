import Combine
import Foundation

final class ChallengeService: ObservableObject {
    @Published var streak: Streak {
        didSet { save() }
    }
    @Published var challenges: [DailyChallenge] {
        didSet { save() }
    }
    @Published var badges: [Badge] {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private let key = "fmf.challenges"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let data = defaults.data(forKey: key),
           let payload = try? decoder.decode(ChallengePayload.self, from: data) {
            self.streak = payload.streak
            self.challenges = payload.challenges
            self.badges = payload.badges
        } else {
            self.streak = .sample
            self.challenges = DailyChallenge.sample
            self.badges = Badge.sample
        }
    }

    private func save() {
        let payload = ChallengePayload(streak: streak, challenges: challenges, badges: badges)
        if let data = try? encoder.encode(payload) {
            defaults.set(data, forKey: key)
        }
    }
}

private struct ChallengePayload: Codable {
    let streak: Streak
    let challenges: [DailyChallenge]
    let badges: [Badge]
}

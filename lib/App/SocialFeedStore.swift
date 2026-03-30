import Combine
import Foundation

final class SocialFeedStore: ObservableObject {
    @Published var checkIns: [CheckIn] {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private let key = "fmf.social.feed"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        if let data = defaults.data(forKey: key),
           let decoded = try? decoder.decode([CheckIn].self, from: data) {
            self.checkIns = decoded
        } else {
            self.checkIns = CheckIn.sample
        }
    }

    func toggleReaction(on checkIn: CheckIn, type: ReactionType) {
        guard let index = checkIns.firstIndex(where: { $0.id == checkIn.id }) else { return }
        var updated = checkIns[index]
        if let reactionIndex = updated.reactions.firstIndex(where: { $0.type == type }) {
            var reaction = updated.reactions[reactionIndex]
            reaction.isSelected.toggle()
            reaction.count += reaction.isSelected ? 1 : -1
            updated.reactions[reactionIndex] = reaction
        }
        checkIns[index] = updated
    }

    private func save() {
        if let data = try? encoder.encode(checkIns) {
            defaults.set(data, forKey: key)
        }
    }
}

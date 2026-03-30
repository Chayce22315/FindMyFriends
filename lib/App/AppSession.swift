import Combine
import Foundation

/// Friends, family, and feature gates (real-life friends require a family).
final class AppSession: ObservableObject {
    @Published var family: FamilyGroup?
    @Published var familyMembers: [FamilyMember]
    @Published var friends: [Friend]

    private let defaults: UserDefaults
    private let familyKey = "fmf.family.data"
    private let membersKey = "fmf.family.members"
    private let friendsKey = "fmf.friends"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: familyKey),
           let decoded = try? JSONDecoder().decode(FamilyGroup.self, from: data) {
            self.family = decoded
        } else {
            self.family = nil
        }
        if let data = defaults.data(forKey: membersKey),
           let decoded = try? JSONDecoder().decode([FamilyMember].self, from: data) {
            self.familyMembers = decoded
        } else {
            self.familyMembers = []
        }
        if let data = defaults.data(forKey: friendsKey),
           let decoded = try? JSONDecoder().decode([Friend].self, from: data) {
            self.friends = decoded
        } else {
            self.friends = []
        }
    }

    var hasFamily: Bool { family != nil }

    func createFamily(named name: String) {
        let group = FamilyGroup(name: name)
        family = group
        persistFamily()
        if familyMembers.isEmpty {
            familyMembers = [
                FamilyMember(name: "You", role: "Organizer", isYou: true),
            ]
            persistMembers()
        }
    }

    func joinFamily(code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count >= 4 else { return false }
        let group = FamilyGroup(name: "Family \(trimmed.suffix(3))", inviteCode: trimmed)
        family = group
        persistFamily()
        if familyMembers.isEmpty {
            familyMembers = [FamilyMember(name: "You", role: "Member", isYou: true)]
            persistMembers()
        }
        return true
    }

    func addFriend(_ friend: Friend) {
        guard hasFamily else { return }
        guard !friends.contains(where: { $0.id == friend.id }) else { return }
        friends.append(friend)
        persistFriends()
    }

    func removeFriend(_ friend: Friend) {
        friends.removeAll { $0.id == friend.id }
        persistFriends()
    }

    func updateFriendLocation(id: UUID, lat: Double, lon: Double) {
        guard let i = friends.firstIndex(where: { $0.id == id }) else { return }
        friends[i].latitude = lat
        friends[i].longitude = lon
        persistFriends()
    }

    private func persistFamily() {
        if let family, let data = try? JSONEncoder().encode(family) {
            defaults.set(data, forKey: familyKey)
        } else {
            defaults.removeObject(forKey: familyKey)
        }
    }

    private func persistMembers() {
        if let data = try? JSONEncoder().encode(familyMembers) {
            defaults.set(data, forKey: membersKey)
        }
    }

    private func persistFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            defaults.set(data, forKey: friendsKey)
        }
    }
}

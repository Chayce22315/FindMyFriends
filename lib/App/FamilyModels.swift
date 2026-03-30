import Foundation

struct FamilyGroup: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var inviteCode: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, inviteCode: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode ?? Self.generateInviteCode()
        self.createdAt = createdAt
    }

    private static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0 ..< 6).map { _ in chars.randomElement()! })
    }
}

struct FamilyMember: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var role: String
    var isYou: Bool

    init(id: UUID = UUID(), name: String, role: String, isYou: Bool = false) {
        self.id = id
        self.name = name
        self.role = role
        self.isYou = isYou
    }
}

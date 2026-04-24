import Foundation

struct BackendRosterMember: Codable, Identifiable, Hashable {
    var id: String { deviceId }
    let deviceId: String
    let name: String
    let role: String
    let joinedAt: String?
}

struct BackendRosterResponse: Codable {
    let familyId: UUID
    let name: String
    let inviteCode: String
    let members: [BackendRosterMember]
}

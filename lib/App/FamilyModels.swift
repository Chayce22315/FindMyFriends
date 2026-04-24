import Foundation

struct FamilyGroup: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var inviteCode: String
    var inviteURL: String?
    var createdAt: Date

    init(id: UUID = UUID(), name: String, inviteCode: String? = nil, inviteURL: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode ?? Self.generateInviteCode()
        self.inviteURL = inviteURL
        self.createdAt = createdAt
    }

    /// Shareable join link: always prefers the server’s `inviteUrl` from create/join so it never rewrites to localhost.
    func inviteLink(baseURL: String) -> URL {
        if let inviteURL, let url = URL(string: inviteURL), url.scheme == "http" || url.scheme == "https" {
            return url
        }
        let fallback = Self.defaultInviteURL(for: inviteCode, baseURL: baseURL)
        if let u = URL(string: fallback) { return u }
        let last = "\(InviteServerConfiguration.productionBaseURL)/invite/\(inviteCode)"
        return URL(string: last)!
    }

    static func defaultInviteURL(for code: String, baseURL: String) -> String {
        let normalized = normalizedBaseURL(baseURL)
        return "\(normalized)/invite/\(code)"
    }

    private static func normalizedBaseURL(_ baseURL: String) -> String {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return InviteServerConfiguration.productionBaseURL
        }
        let withScheme = trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://")
            ? trimmed
            : "http://\(trimmed)"
        return withScheme.hasSuffix("/") ? String(withScheme.dropLast()) : withScheme
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

import Foundation

extension Notification.Name {
    /// Posted after optional backend URL is applied; userInfo contains `"code"` (invite string).
    static let fmfOpenFamilyJoin = Notification.Name("fmf.openFamilyJoin")
}

enum InviteDeepLink {
    /// Handles `findmyfriends://join?family=CODE&api=BASE` from the invite web page or Messages.
    static func handle(_ url: URL, settings: AppSettings) {
        guard url.scheme?.lowercased() == "findmyfriends" else { return }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        var items: [String: String] = [:]
        for item in components.queryItems ?? [] {
            guard let value = item.value, !value.isEmpty else { continue }
            items[item.name.lowercased()] = value
        }

        guard let rawCode = items["family"] ?? items["code"] else { return }
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count >= 4 else { return }

        if let api = items["api"], let decoded = api.removingPercentEncoding ?? Optional(api) {
            let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                settings.backendBaseURL = trimmed
            }
        }

        NotificationCenter.default.post(
            name: .fmfOpenFamilyJoin,
            object: nil,
            userInfo: ["code": code]
        )
    }
}

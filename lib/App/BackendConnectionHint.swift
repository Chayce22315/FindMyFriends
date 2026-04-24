import Foundation

enum BackendConnectionHint {
    /// Human-readable follow-up when the invite backend is unreachable (common on a real device with `localhost`).
    static let afterUnreachable: String = "On a real iPhone, localhost is the phone itself. Deploy the server (e.g. free Render/Railway) and paste its HTTPS URL in Profile → Backend."

    static func isLikelyUnreachableLocalBackend(baseURL: String) -> Bool {
        let t = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !t.isEmpty else { return false }
        if t.hasPrefix("http://localhost") || t.hasPrefix("https://localhost") { return true }
        if t.hasPrefix("http://127.0.0.1") || t.hasPrefix("https://127.0.0.1") { return true }
        if t.hasPrefix("http://0.0.0.0") || t.hasPrefix("https://0.0.0.0") { return true }
        return false
    }

    /// Maps URLSession / system errors to clearer copy for invite flows.
    static func friendlyMessage(for error: Error, baseURL: String) -> String {
        if let backendError = error as? BackendClientError, case .invalidBaseURL = backendError {
            return "Add your invite server URL under You → Backend (HTTPS from a free host works on iPhone)."
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .dnsLookupFailed, .notConnectedToInternet:
                var msg = urlError.localizedDescription
                if isLikelyUnreachableLocalBackend(baseURL: baseURL) {
                    msg += "\n\n" + Self.afterUnreachable
                } else if baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    msg += "\n\nSet your backend URL in Profile → Backend (deploy the folder `backend/` to a free host if you are not running it on a computer)."
                } else {
                    msg += "\n\nCheck that the URL in Profile → Backend matches your running server (try opening \(baseURL.trimmingCharacters(in: .whitespacesAndNewlines))/health in Safari)."
                }
                return msg
            default:
                break
            }
        }
        return error.localizedDescription
    }
}

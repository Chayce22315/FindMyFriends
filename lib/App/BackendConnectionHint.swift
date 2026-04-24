import Foundation

enum BackendConnectionHint {
    static let localhostOnDeviceHint =
        "This phone was still using localhost, which points at the iPhone itself — not your Render server. Open You → Invite server and paste your HTTPS URL (e.g. https://backend-findmyfriends-1nhg.onrender.com)."

    static func isLoopbackBackendURL(_ raw: String) -> Bool {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !t.isEmpty else { return false }
        return t.hasPrefix("http://localhost")
            || t.hasPrefix("https://localhost")
            || t.hasPrefix("http://127.0.0.1")
            || t.hasPrefix("https://127.0.0.1")
            || t.hasPrefix("http://0.0.0.0")
            || t.hasPrefix("https://0.0.0.0")
    }

    static func friendlyMessage(for error: Error, baseURL: String) -> String {
        if let backendError = error as? BackendClientError, case .invalidBaseURL = backendError {
            return "Add your invite server URL under You (sparkles tab) → Invite server — use https://… from Render, not localhost on a real phone."
        }
        if error is DecodingError {
            return "The server replied in an unexpected format. Update this app and redeploy the backend from the latest repo, then try again."
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .dnsLookupFailed, .notConnectedToInternet:
                var msg = urlError.localizedDescription
                if isLoopbackBackendURL(baseURL) {
                    msg += "\n\n" + Self.localhostOnDeviceHint
                } else if baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    msg += "\n\nPaste your Render URL under You → Invite server (no trailing slash)."
                } else {
                    msg += "\n\nCheck the URL under You → Invite server. If you use Render’s free tier, wait 30–60s and try again while the service wakes up."
                }
                return msg
            default:
                break
            }
        }
        return error.localizedDescription
    }
}

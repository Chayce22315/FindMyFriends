import Foundation

/// Stable per-install id for roster sync (not tied to Apple ID).
enum DeviceIdentity {
    private static let key = "fmf.device.installId"

    static var id: String {
        let d = UserDefaults.standard
        if let existing = d.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let fresh = UUID().uuidString
        d.set(fresh, forKey: key)
        return fresh
    }
}

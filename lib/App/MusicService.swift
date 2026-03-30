import Foundation
import MusicKit

final class MusicService: ObservableObject {
    @Published private(set) var status: MusicAuthorization.Status = MusicAuthorization.currentStatus

    var isAuthorized: Bool { status == .authorized }

    func refreshStatus() {
        status = MusicAuthorization.currentStatus
    }

    func requestAccess() async {
        let newStatus = await MusicAuthorization.request()
        await MainActor.run {
            status = newStatus
        }
    }

    var statusLabel: String {
        switch status {
        case .authorized:
            return "Connected"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not connected"
        @unknown default:
            return "Unknown"
        }
    }
}

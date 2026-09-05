import Foundation
import SwiftUI

/// Lightweight app-side Live Activity state.
/// The standalone app no longer ships a WidgetKit extension, so this keeps the
/// profile UI buildable without requiring a widget target or ActivityKit code.
@MainActor
final class LiveActivityManager: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var statusLabel = "Live Activities are unavailable in this build."

    func end() async {
        isRunning = false
        statusLabel = "Live Activities are unavailable in this build."
    }
}

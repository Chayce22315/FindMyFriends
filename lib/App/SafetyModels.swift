import Foundation

struct SafetyCheck: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let scheduledAt: Date
    let isActive: Bool

    static let sample: [SafetyCheck] = [
        SafetyCheck(title: "Night check-in", subtitle: "Notify family at 10:30 PM", scheduledAt: .now.addingTimeInterval(3600 * 6), isActive: true),
        SafetyCheck(title: "Arrival ping", subtitle: "Ping when you reach Home Base", scheduledAt: .now.addingTimeInterval(3600 * 2), isActive: false),
        SafetyCheck(title: "Flight landed", subtitle: "Send when you land", scheduledAt: .now.addingTimeInterval(3600 * 9), isActive: true),
    ]
}

import Foundation

struct Achievement: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let progress: Double
    let goal: Double

    var isUnlocked: Bool { progress >= goal }

    var progressText: String {
        "\(Int(progress))/\(Int(goal))"
    }

    static let sample: [Achievement] = [
        Achievement(title: "First Check-In", subtitle: "Share a location with family", icon: "location.fill", progress: 1, goal: 1),
        Achievement(title: "Day Trip", subtitle: "Travel 10 miles in a day", icon: "car.fill", progress: 6, goal: 10),
        Achievement(title: "Explorer", subtitle: "Visit 5 saved places", icon: "map.fill", progress: 3, goal: 5),
        Achievement(title: "Night Owl", subtitle: "Be active after 10pm", icon: "moon.stars.fill", progress: 0, goal: 1),
        Achievement(title: "Ring Closer", subtitle: "Close activity rings 3 days", icon: "heart.fill", progress: 2, goal: 3),
    ]
}

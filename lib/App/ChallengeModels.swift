import Foundation

struct Badge: Identifiable, Hashable, Codable {
    var id: UUID
    let title: String
    let subtitle: String
    let icon: String
    let isUnlocked: Bool

    init(id: UUID = UUID(), title: String, subtitle: String, icon: String, isUnlocked: Bool) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isUnlocked = isUnlocked
    }

    static let sample: [Badge] = [
        Badge(title: "First Flight", subtitle: "Took off once", icon: "airplane", isUnlocked: true),
        Badge(title: "Trail Blazer", subtitle: "10 km in a day", icon: "leaf.fill", isUnlocked: false),
        Badge(title: "Night Runner", subtitle: "After 10 PM", icon: "moon.stars.fill", isUnlocked: true),
    ]
}

struct DailyChallenge: Identifiable, Hashable, Codable {
    var id: UUID
    let title: String
    let progress: Int
    let goal: Int
    let rewardXP: Int

    init(id: UUID = UUID(), title: String, progress: Int, goal: Int, rewardXP: Int) {
        self.id = id
        self.title = title
        self.progress = progress
        self.goal = goal
        self.rewardXP = rewardXP
    }

    var isCompleted: Bool { progress >= goal }

    var progressText: String { "\(progress)/\(goal)" }

    static let sample: [DailyChallenge] = [
        DailyChallenge(title: "Walk 2 km", progress: 1, goal: 2, rewardXP: 120),
        DailyChallenge(title: "Check in twice", progress: 1, goal: 2, rewardXP: 80),
        DailyChallenge(title: "Visit a new place", progress: 0, goal: 1, rewardXP: 150),
    ]
}

struct Streak: Identifiable, Hashable, Codable {
    var id: UUID
    let current: Int
    let best: Int
    let updatedAt: Date

    init(id: UUID = UUID(), current: Int, best: Int, updatedAt: Date) {
        self.id = id
        self.current = current
        self.best = best
        self.updatedAt = updatedAt
    }

    static let sample = Streak(current: 4, best: 9, updatedAt: .now)
}

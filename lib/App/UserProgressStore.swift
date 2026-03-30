import Combine
import Foundation

final class UserProgressStore: ObservableObject {
    @Published private(set) var xp: Int
    @Published private(set) var lastLevel: Int
    @Published var lastLevelUpAt: Date?

    private let defaults: UserDefaults
    private let xpKey = "fmf.xp"
    private let levelKey = "fmf.lastLevel"
    private let levelUpKey = "fmf.levelUpAt"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.xp = defaults.integer(forKey: xpKey)
        self.lastLevel = max(1, defaults.integer(forKey: levelKey))
        if defaults.object(forKey: levelUpKey) != nil {
            self.lastLevelUpAt = defaults.object(forKey: levelUpKey) as? Date
        }
        if lastLevel == 0 { lastLevel = 1 }
    }

    static func level(for xp: Int) -> Int {
        max(1, 1 + Int(floor(sqrt(Double(max(0, xp)) / 120.0))))
    }

    var level: Int {
        Self.level(for: xp)
    }

    /// XP at the start of `level` (1-based).
    private static func xpThreshold(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        let k = level - 1
        return k * k * 120
    }

    var xpIntoLevel: Int {
        let l = level
        return xp - Self.xpThreshold(for: l)
    }

    var xpForNextLevel: Int {
        let l = level
        let next = Self.xpThreshold(for: l + 1)
        let cur = Self.xpThreshold(for: l)
        return max(1, next - cur)
    }

    func addXP(_ amount: Int, reason: String = "") {
        guard amount > 0 else { return }
        let before = level
        xp += amount
        defaults.set(xp, forKey: xpKey)
        let after = level
        if after > before {
            lastLevel = after
            defaults.set(after, forKey: levelKey)
            lastLevelUpAt = .now
            defaults.set(lastLevelUpAt, forKey: levelUpKey)
            NotificationCenter.default.post(name: .didLevelUp, object: after)
        }
    }

    func syncXPFromSteps(_ steps: Int) {
        let grant = steps / 80
        guard grant > 0 else { return }
        let key = "fmf.xp.steps.\(Calendar.current.startOfDay(for: .now).timeIntervalSince1970)"
        let already = defaults.integer(forKey: key)
        let delta = grant - already
        if delta > 0 {
            addXP(delta * 2, reason: "steps")
            defaults.set(grant, forKey: key)
        }
    }
}

extension Notification.Name {
    static let didLevelUp = Notification.Name("fmf.didLevelUp")
}

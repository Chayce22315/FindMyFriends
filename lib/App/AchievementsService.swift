import Combine
import Foundation

final class AchievementsService: ObservableObject {
    @Published var achievements: [Achievement] = Achievement.sample
}

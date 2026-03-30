import Combine
import Foundation

final class SafetyService: ObservableObject {
    @Published var checks: [SafetyCheck] = SafetyCheck.sample
}

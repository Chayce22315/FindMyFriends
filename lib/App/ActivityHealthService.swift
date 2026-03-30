import Combine
import Foundation
import HealthKit

final class ActivityHealthService: ObservableObject {
    @Published private(set) var stepsToday: Int = 0
    @Published private(set) var activeCalories: Double = 0
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var healthDataAvailable: Bool = HKHealthStore.isHealthDataAvailable()

    /// Goals for ring UI
    let stepGoal: Int = 10_000
    let activeCalorieGoal: Double = 450

    private let store = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    func requestAccess() {
        guard healthDataAvailable else { return }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return }

        let read: Set<HKObjectType> = [stepType, energyType]
        store.requestAuthorization(toShare: [], read: read) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = ok
                if ok {
                    self?.registerStepObserver()
                    self?.refreshToday()
                }
            }
        }
    }

    func refreshToday() {
        guard healthDataAvailable else { return }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        let stepQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                self?.stepsToday = Int(steps)
            }
        }

        let energyQuery = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            let kcal = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            DispatchQueue.main.async {
                self?.activeCalories = kcal
            }
        }

        store.execute(stepQuery)
        store.execute(energyQuery)
    }

    private func registerStepObserver() {
        guard observerQuery == nil else { return }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, _ in
            self?.refreshToday()
            completionHandler()
        }
        store.execute(query)
        observerQuery = query
    }
}

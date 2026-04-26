import Combine
import Foundation
import HealthKit

final class ActivityHealthService: ObservableObject {
    @Published private(set) var stepsToday: Int = 0
    @Published private(set) var activeCalories: Double = 0
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published private(set) var healthDataAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var lastHealthError: String?

    /// Goals for ring UI
    let stepGoal: Int = 10_000
    let activeCalorieGoal: Double = 450

    private let store = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    init() {
        if healthDataAvailable,
           let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let status = store.authorizationStatus(for: stepType)
            updateAuthorizationStatus(status)
            if isHealthReadUnlocked {
                registerStepObserver()
                refreshToday()
            }
        }
    }

    func requestAccess() {
        guard healthDataAvailable else { return }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return }

        let read: Set<HKObjectType> = [stepType, energyType]
        store.requestAuthorization(toShare: [], read: read) { [weak self] ok, error in
            DispatchQueue.main.async {
                self?.lastHealthError = error?.localizedDescription
                self?.updateAuthorizationStatus()
                if self?.isHealthReadUnlocked == true {
                    self?.registerStepObserver()
                    self?.refreshToday()
                }
            }
        }
    }

    /// Re-check authorization and reload today’s samples.
    func refreshAuthorizationAndData() {
        updateAuthorizationStatus()
        refreshToday()
    }

    func refreshToday() {
        guard healthDataAvailable else { return }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return }
        let status = store.authorizationStatus(for: stepType)
        updateAuthorizationStatus(status)
        guard isHealthReadUnlocked else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])

        let stepQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let error {
                DispatchQueue.main.async { self?.lastHealthError = error.localizedDescription }
            }
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                self?.stepsToday = Int(steps)
            }
        }

        let energyQuery = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let error {
                DispatchQueue.main.async { self?.lastHealthError = error.localizedDescription }
            }
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

    private func updateAuthorizationStatus() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let status = store.authorizationStatus(for: stepType)
        updateAuthorizationStatus(status)
    }

    private func updateAuthorizationStatus(_ status: HKAuthorizationStatus) {
        if Thread.isMainThread {
            authorizationStatus = status
            recomputeIsAuthorized()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.authorizationStatus = status
                self?.recomputeIsAuthorized()
            }
        }
    }

    private func isReadAccessDenied(_ status: HKAuthorizationStatus) -> Bool {
        status == .sharingDenied
    }

    /// For **read** types Apple often leaves status `.notDetermined` even after the user allows reading.
    /// Treat only explicit **denial** as blocked so Health queries can run after authorization.
    var isHealthReadUnlocked: Bool {
        !isReadAccessDenied(authorizationStatus)
    }

    private func recomputeIsAuthorized() {
        isAuthorized = isHealthReadUnlocked
    }
}

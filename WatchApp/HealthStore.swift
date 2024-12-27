import HealthKit

class HealthStore {
    var healthStore: HKHealthStore?

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let healthStore = healthStore else { return }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        healthStore.requestAuthorization(toShare: [], read: [stepType, heartRateType]) { success, error in
            completion(success)
        }
    }
}

import Foundation
import HealthKit

class ContentViewModel: ObservableObject {
    private var healthStore: HealthStore?
    @Published var stepCount: Int = 0
    @Published var heartRate: Double = 0.0
    private var heartRateQuery: HKObserverQuery?
    private var stepCountQuery: HKObserverQuery?

    init(healthStore: HealthStore? = nil) {
        self.healthStore = healthStore ?? HealthStore()
        self.healthStore?.requestAuthorization { success in
            if success {
                self.startObservingStepCount()
                self.startObservingHeartRate()
            }
        }
    }

    private func startObservingStepCount() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Error observing step count: \(error.localizedDescription)")
                return
            }
            self?.fetchStepCount()
        }
        healthStore?.healthStore?.execute(query)
        stepCountQuery = query
    }

    private func startObservingHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Error observing heart rate: \(error.localizedDescription)")
                return
            }
            self?.fetchHeartRate()
        }
        healthStore?.healthStore?.execute(query)
        heartRateQuery = query
    }

    private func fetchStepCount() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }

            DispatchQueue.main.async {
                self.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }

        healthStore?.healthStore?.execute(query)
    }

    private func fetchHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample], let sample = samples.last else {
                return
            }

            DispatchQueue.main.async {
                self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }

        healthStore?.healthStore?.execute(query)
    }

    deinit {
        if let query = heartRateQuery {
            healthStore?.healthStore?.stop(query)
        }
        if let query = stepCountQuery {
            healthStore?.healthStore?.stop(query)
        }
    }
}

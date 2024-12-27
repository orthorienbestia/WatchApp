import WidgetKit
import SwiftUI
import HealthKit
import Lottie

struct HealthEntry: TimelineEntry {
    let date: Date
    let stepCount: Int
    let heartRate: Double
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HealthEntry {
        HealthEntry(date: Date(), stepCount: 0, heartRate: 0.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthEntry) -> ()) {
        let entry = HealthEntry(date: Date(), stepCount: 0, heartRate: 0.0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthEntry>) -> ()) {
        var entries: [HealthEntry] = []

        // Fetch health data
        let healthStore = HKHealthStore()
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let stepQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }

            let stepCount = Int(sum.doubleValue(for: HKUnit.count()))

            let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKQuantitySample], let sample = samples.last else {
                    return
                }

                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))

                // Create a timeline entry
                let entry = HealthEntry(date: Date(), stepCount: stepCount, heartRate: heartRate)
                entries.append(entry)

                // Create a timeline with one entry
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            }

            healthStore.execute(heartRateQuery)
        }

        healthStore.execute(stepQuery)
    }
}

struct HealthWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack {
                LottieView(filename: "walking_man")
                    .frame(width: 24, height: 24)
                Text("\(entry.stepCount) steps")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 10)

            HStack {
                LottieView(filename: "heart_anim")
                    .frame(width: 24, height: 24)
                Text("\(entry.heartRate, specifier: "%.1f") bpm")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}



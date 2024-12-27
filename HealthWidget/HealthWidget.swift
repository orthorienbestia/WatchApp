import WidgetKit
import SwiftUI
import HealthKit

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
    
    let healthStore = HKHealthStore()
        
        private func requestAuthorization(completion: @escaping (Bool) -> Void) {
            let typesToRead: Set<HKObjectType> = [
                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                HKObjectType.quantityType(forIdentifier: .heartRate)!
            ]
            
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                completion(success)
            }
        }

        func getTimeline(in context: Context, completion: @escaping (Timeline<HealthEntry>) -> ()) {
            requestAuthorization { success in
                guard success else {
                    let entry = HealthEntry(date: Date(), stepCount: 0, heartRate: 0.0)
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
                    completion(timeline)
                    return
                }
                
                var entries: [HealthEntry] = []
                let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
                let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
                
                let now = Date()
                let startOfDay = Calendar.current.startOfDay(for: now)
                let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
                
                let group = DispatchGroup()
                var totalSteps = 0
                var latestHeartRate = 0.0
                
                group.enter()
                let stepQuery = HKStatisticsQuery(quantityType: stepType,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum) { _, result, error in
                    defer { group.leave() }
                    
                    if let sum = result?.sumQuantity() {
                        totalSteps = Int(sum.doubleValue(for: HKUnit.count()))
                    }
                }
                
                group.enter()
                let heartRateQuery = HKSampleQuery(sampleType: heartRateType,
                                                 predicate: predicate,
                                                 limit: 1,
                                                 sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                    defer { group.leave() }
                    
                    if let sample = samples?.first as? HKQuantitySample {
                        latestHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    }
                }
                
                healthStore.execute(stepQuery)
                healthStore.execute(heartRateQuery)
                
                group.notify(queue: .main) {
                    let entry = HealthEntry(date: now, stepCount: totalSteps, heartRate: latestHeartRate)
                    entries.append(entry)
                    
                    // Update every 15 minutes
                    let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(15 * 60)))
                    completion(timeline)
                }
            }
        }

//    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthEntry>) -> ()) {
//        var entries: [HealthEntry] = []
//
//        // Fetch data from shared user defaults
//        if let groupUserDefaults = UserDefaults(suiteName: "group.com.example.HealthData") {
//            let stepCount = groupUserDefaults.integer(forKey: "stepCount")
//            let heartRate = groupUserDefaults.double(forKey: "heartRate")
//            print("Data fetched: steps = \(stepCount), heart rate = \(heartRate)")
//
//            // Create a timeline entry
//            let entry = HealthEntry(date: Date(), stepCount: stepCount, heartRate: heartRate)
//            entries.append(entry)
//        } else {
//            print("Failed to access shared user defaults")
//        }
//
//        // Generate a timeline with a single entry
//        let timeline = Timeline(entries: entries, policy: .atEnd)
//        completion(timeline)
//    }
}

struct HealthWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.white)
                Text(entry.stepCount == 0 ? "No data" : "\(entry.stepCount) steps")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 10)

            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.white)
                Text(entry.heartRate == 0.0 ? "No data" : "\(entry.heartRate, specifier: "%.1f") bpm")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}


struct HealthWidget: Widget {
    let kind: String = "HealthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HealthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Health Widget")
        .description("Displays your current step count and heart rate.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

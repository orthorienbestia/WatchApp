import WidgetKit
import SwiftUI
import HealthKit

struct HealthEntry: TimelineEntry {
    let date: Date
    let stepCount: Int
    let heartRate: Double
}

struct Provider: TimelineProvider {
    let healthStore = HKHealthStore()
    
    func placeholder(in context: Context) -> HealthEntry {
        HealthEntry(date: Date(), stepCount: 0, heartRate: 0.0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HealthEntry) -> ()) {
        let entry = HealthEntry(date: Date(), stepCount: 0, heartRate: 0.0)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthEntry>) -> ()) {
        // Request authorization first
        let healthTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            let entry = HealthEntry(date: Date(), stepCount: 0, heartRate: 0.0)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
            completion(timeline)
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: healthTypes) { success, error in
            if !success {
                let entry = HealthEntry(date: Date(), stepCount: 0, heartRate: 0.0)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
                completion(timeline)
                return
            }
            
            // Fetch today's data
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            
            let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            let heartType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            // Create a dispatch group to wait for both queries
            let group = DispatchGroup()
            
            var steps = 0
            var heartRate = 0.0
            
            // Query steps
            group.enter()
            let stepQuery = HKStatisticsQuery(quantityType: stepType,
                                            quantitySamplePredicate: predicate,
                                            options: .cumulativeSum) { _, result, _ in
                if let sum = result?.sumQuantity() {
                    steps = Int(sum.doubleValue(for: HKUnit.count()))
                }
                group.leave()
            }
            
            // Query heart rate
            group.enter()
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let heartQuery = HKSampleQuery(sampleType: heartType,
                                         predicate: predicate,
                                         limit: 1,
                                         sortDescriptors: [sortDescriptor]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                }
                group.leave()
            }
            
            // Execute queries
            healthStore.execute(stepQuery)
            healthStore.execute(heartQuery)
            
            // When both queries complete
            group.notify(queue: .main) {
                let entry = HealthEntry(date: now, stepCount: steps, heartRate: heartRate)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
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
//}

struct HealthWidgetEntryView: View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

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
        .containerBackground(for: .widget) {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
        }
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

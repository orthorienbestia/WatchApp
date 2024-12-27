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

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthEntry>) -> ()) {
        var entries: [HealthEntry] = []

        let groupUserDefaults = UserDefaults(suiteName: "group.com.example.HealthData")
        let stepCount = groupUserDefaults?.integer(forKey: "stepCount") ?? 0
        let heartRate = groupUserDefaults?.double(forKey: "heartRate") ?? 0.0

        let entry = HealthEntry(date: Date(), stepCount: stepCount, heartRate: heartRate)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct HealthWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Steps: \(entry.stepCount)")
                .font(.headline)
                .foregroundColor(.white)
            Text("Heart Rate: \(entry.heartRate, specifier: "%.1f") bpm")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .containerBackground(Color.clear, for: .widget)
    }
}


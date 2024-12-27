import WidgetKit
import SwiftUI

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

        // Fetch data from shared user defaults
        if let groupUserDefaults = UserDefaults(suiteName: "group.com.example.HealthData") {
            let stepCount = groupUserDefaults.integer(forKey: "stepCount")
            let heartRate = groupUserDefaults.double(forKey: "heartRate")
            print("Data fetched: steps = \(stepCount), heart rate = \(heartRate)")

            // Create a timeline entry
            let entry = HealthEntry(date: Date(), stepCount: stepCount, heartRate: heartRate)
            entries.append(entry)
        } else {
            print("Failed to access shared user defaults")
        }

        // Generate a timeline with a single entry
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

@main
struct HealthWidget: Widget {
    let kind: String = "HealthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HealthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Health Widget")
        .description("Displays your current step count and heart rate.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

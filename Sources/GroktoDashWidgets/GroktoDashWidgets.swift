import WidgetKit
import SwiftUI
import GroktoDashKit

/// Stub — widget timeline provider (M4).
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), activeRuns: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), activeRuns: 0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date(), activeRuns: 0)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let activeRuns: Int
}

struct GroktoDashWidgetsEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack {
            Image(systemName: "brain.head.profile")
                .font(.title)
            Text("Active Runs: \(entry.activeRuns)")
                .font(.caption)
        }
    }
}

struct GroktoDashWidget: Widget {
    let kind = "GroktoDashWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GroktoDashWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("GroktoDash")
        .description("See your active Hermes runs at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

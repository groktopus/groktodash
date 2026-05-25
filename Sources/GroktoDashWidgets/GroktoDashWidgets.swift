import WidgetKit
import SwiftUI

// MARK: - Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let activeRuns: Int
    let recentConversations: [ConversationPreview]
}

struct ConversationPreview: Sendable, Identifiable {
    let title: String
    let snippet: String
    let updatedAt: Date

    var id: String { title + snippet.prefix(10) }
}

// MARK: - Provider

struct GroktoDashProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            activeRuns: 2,
            recentConversations: [
                ConversationPreview(title: "Bug fix session", snippet: "The issue was...", updatedAt: Date()),
                ConversationPreview(title: "API design review", snippet: "We should use...", updatedAt: Date().addingTimeInterval(-3600)),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 5 minutes or when the app updates the timeline
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        completion(timeline)
    }

    /// Read data from the shared App Group container.
    private func loadEntry() -> WidgetEntry {
        // Widgets can't directly access SwiftData. Instead, the app
        // writes a JSON snapshot to App Group UserDefaults.
        guard let shared = UserDefaults(suiteName: "group.com.groktopus.groktodash") else {
            return WidgetEntry(date: Date(), activeRuns: 0, recentConversations: [])
        }

        let activeRuns = shared.integer(forKey: "widget.activeRuns")
        let conversations: [ConversationPreview] = {
            guard let data = shared.data(forKey: "widget.recentConversations"),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }
            return json.prefix(5).compactMap { item in
                guard let title = item["title"] as? String,
                      let snippet = item["snippet"] as? String,
                      let timestamp = item["updatedAt"] as? Double else { return nil }
                return ConversationPreview(
                    title: title,
                    snippet: snippet,
                    updatedAt: Date(timeIntervalSince1970: timestamp)
                )
            }
        }()

        return WidgetEntry(date: Date(), activeRuns: activeRuns, recentConversations: conversations)
    }
}

// MARK: - Active Runs Widget (Medium)

struct ActiveRunsWidget: View {
    var entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                Text("GroktoDash")
                    .font(.headline)
                Spacer()
                if entry.activeRuns > 0 {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("\(entry.activeRuns) active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if entry.recentConversations.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "text.bubble")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No conversations yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.recentConversations.prefix(3)) { conv in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(conv.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(conv.snippet)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }

            Spacer()

            HStack {
                Text("Updated \(entry.date, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Tap to open")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
    }
}

// MARK: - Recent Conversations Widget (Large)

struct RecentConversationsWidget: View {
    var entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                Text("GroktoDash")
                    .font(.headline)
                Spacer()
            }

            if entry.recentConversations.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "text.bubble")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("Ask Hermes to get started")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(entry.recentConversations.prefix(5)) { conv in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(conv.title)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Text(conv.updatedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(conv.snippet)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)

                    if conv.title != entry.recentConversations.last?.title {
                        Divider()
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Widget Configuration

struct ActiveRunsWidgetEntry: Widget {
    let kind = "ActiveRunsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GroktoDashProvider()) { entry in
            ActiveRunsWidget(entry: entry)
        }
        .configurationDisplayName("Active Runs")
        .description("See your active Hermes runs at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

struct RecentConversationsWidgetEntry: Widget {
    let kind = "RecentConversationsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GroktoDashProvider()) { entry in
            RecentConversationsWidget(entry: entry)
        }
        .configurationDisplayName("Recent Conversations")
        .description("Recent conversations with Hermes.")
        .supportedFamilies([.systemLarge])
    }
}

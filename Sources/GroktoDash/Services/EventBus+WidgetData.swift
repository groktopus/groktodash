import Foundation

/// Widget data sharing support for EventBus.
///
/// Widgets can't directly access SwiftData. Instead, the app writes
/// a JSON snapshot to App Group UserDefaults for widgets to read.
extension EventBus {

    // MARK: - App Group

    /// The App Group identifier shared between the app and extensions.
    static let appGroup = "group.com.groktopus.groktodash"

    /// The shared UserDefaults for the App Group.
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    // MARK: - Widget Data

    /// Update widget data with current state.
    func updateWidgetData() {
        guard let shared = Self.sharedDefaults else { return }

        // Active runs count
        shared.set(isRunning ? 1 : 0, forKey: "widget.activeRuns")

        // Recent conversations (last 5)
        let recentConversations = conversations.prefix(5).map { conv -> [String: Any] in
            let snippet = conv.messages
                .sorted(by: { $0.timestamp < $1.timestamp })
                .last?
                .content
                .prefix(200) ?? ""

            return [
                "title": conv.title,
                "snippet": String(snippet),
                "id": conv.id.uuidString,
                "updatedAt": conv.updatedAt.timeIntervalSince1970,
            ]
        }
        if let data = try? JSONSerialization.data(withJSONObject: recentConversations) {
            shared.set(data, forKey: "widget.recentConversations")
        }

        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
}

import WidgetKit

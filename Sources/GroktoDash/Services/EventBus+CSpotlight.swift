import CoreSpotlight
import SwiftData
import OSLog

/// Spotlight indexing support for EventBus.
///
/// Conversations are indexed with their content, title, and metadata
/// so users can find past conversations via Spotlight (⌘Space).
extension EventBus {

    /// Index a conversation for Spotlight search.
    func indexConversation(_ conversation: Conversation) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = conversation.title
        attributeSet.contentDescription = conversation.messages
            .sorted(by: { $0.timestamp < $1.timestamp })
            .prefix(3)
            .map { "\($0.role == .user ? "You" : "Hermes"): \($0.content.prefix(120))" }
            .joined(separator: "\n")
        attributeSet.contentCreationDate = conversation.createdAt
        attributeSet.contentModificationDate = conversation.updatedAt
        attributeSet.keywords = conversation.messages
            .flatMap { $0.content.components(separatedBy: .whitespacesAndNewlines) }
            .filter { $0.count > 3 }
            .prefix(50)
            .map { String($0) }

        let item = CSSearchableItem(
            uniqueIdentifier: "conversation.\(conversation.id.uuidString)",
            domainIdentifier: "com.groktopus.groktodash.conversation",
            attributeSet: attributeSet
        )
        item.expirationDate = Date().addingTimeInterval(90 * 24 * 3600) // 90 days

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                os.Logger().warning("Spotlight index error: \(error.localizedDescription)")
            }
        }
    }

    /// Remove a conversation from Spotlight.
    func deindexConversation(_ conversation: Conversation) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: ["conversation.\(conversation.id.uuidString)"]
        ) { error in
            if let error {
                os.Logger().warning("Spotlight deindex error: \(error.localizedDescription)")
            }
        }
    }
}

/// Handle Spotlight deeplink to a specific conversation.
extension EventBus {
    /// Resolve a Spotlight search result to a conversation and select it.
    func handleSpotlightActivity(_ activity: NSUserActivity) -> Bool {
        guard activity.activityType == CSSearchableItemActionType,
              let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              identifier.hasPrefix("conversation.") else {
            return false
        }
        let uuidString = String(identifier.dropFirst("conversation.".count))
        guard let uuid = UUID(uuidString: uuidString),
              let conv = conversations.first(where: { $0.id == uuid }) else {
            return false
        }
        selectConversation(conv)
        return true
    }
}

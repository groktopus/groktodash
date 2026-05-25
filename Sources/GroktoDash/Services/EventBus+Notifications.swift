import UserNotifications
import OSLog

/// Notification support for approval workflows.
///
/// Approval requests from Hermes are delivered as actionable macOS
/// notifications with inline Approve and Deny buttons.
extension EventBus {

    // MARK: - Notification Registration

    /// Register notification categories for approval actions.
    static func registerNotificationCategories() {
        let approveAction = UNNotificationAction(
            identifier: "APPROVE_ONCE",
            title: "Allow Once",
            options: .authenticationRequired
        )
        let approveSessionAction = UNNotificationAction(
            identifier: "APPROVE_SESSION",
            title: "Allow Session",
            options: []
        )
        let denyAction = UNNotificationAction(
            identifier: "DENY",
            title: "Deny",
            options: .destructive
        )

        let category = UNNotificationCategory(
            identifier: "com.groktopus.groktodash.approval",
            actions: [approveAction, approveSessionAction, denyAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "Hermes approval request",
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Request notification permission from the user.
    static func requestNotificationPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Approval Notification

    /// Deliver an approval request notification.
    func deliverApprovalNotification(runId: String, tool: String) {
        let content = UNMutableNotificationContent()
        content.title = "Hermes Approval Required"
        content.body = "Run command: \(tool)"
        content.categoryIdentifier = "com.groktopus.groktodash.approval"
        content.sound = .default
        content.userInfo = ["runId": runId, "tool": tool]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "approval.\(runId)",
            content: content,
            trigger: nil  // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                os.Logger().warning("Notification delivery error: \(error.localizedDescription)")
            }
        }
    }

    /// Remove a pending approval notification (e.g., after auto-resolve).
    func removeApprovalNotification(runId: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["approval.\(runId)"]
        )
    }
}

// MARK: - Notification Response Handling

/// Handle notification action responses (Approve/Deny).
extension EventBus {
    func handleNotificationResponse(_ response: UNNotificationResponse) -> Bool {
        guard response.notification.request.content.categoryIdentifier
                == "com.groktopus.groktodash.approval",
              let runId = response.notification.request.content.userInfo["runId"] as? String else {
            return false
        }

        switch response.actionIdentifier {
        case "APPROVE_ONCE":
            resolveApproval(choice: .once)
        case "APPROVE_SESSION":
            resolveApproval(choice: .session)
        case "DENY", UNNotificationDismissActionIdentifier:
            resolveApproval(choice: .deny)
        default:
            return false
        }

        removeApprovalNotification(runId: runId)
        return true
    }
}

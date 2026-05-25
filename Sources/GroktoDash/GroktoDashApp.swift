import SwiftUI
import SwiftData
import UserNotifications
import CoreSpotlight

@main
struct GroktoDashApp: App {
    @State private var eventBus: EventBus?

    init() {
        // Register notification categories on app launch
        EventBus.registerNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            if let bus = eventBus {
                ContentView()
                    .environment(bus)
                    .onAppear {
                        checkPendingIntents(bus: bus)
                    }
                    .onOpenURL { url in
                        handleURL(url, bus: bus)
                    }
                    .onContinueUserActivity(CSSearchableItemActionType) { activity in
                        _ = bus.handleSpotlightActivity(activity)
                    }
            } else {
                GatewaySettingsView { url, apiKey in
                    connect(url: url, apiKey: apiKey)
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 650)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Conversation") {
                    eventBus?.newConversation()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            SidebarCommands()
        }
        .handlesExternalEvents(matching: ["groktodash"])

        MenuBarExtra("GroktoDash", systemImage: "brain.head.profile") {
            if let bus = eventBus {
                MenuBarPopover()
                    .environment(bus)
            }
        }
    }

    // MARK: - App Delegate (notifications)

    /// NSApplicationDelegate for notification response handling.
    /// SwiftUI 6 doesn't need a separate AppDelegate class —
    /// UNUserNotificationCenterDelegate is set in connect().
    @MainActor
    private class NotificationDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
        weak var bus: EventBus?

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            _ = bus?.handleNotificationResponse(response)
            completionHandler()
        }
    }

    // MARK: - Connection

    private func connect(url: URL, apiKey: String?) {
        let schema = Schema([Conversation.self, Message.self, ToolCall.self, Run.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        guard let container = try? ModelContainer(for: schema, configurations: config) else {
            return
        }
        let context = container.mainContext
        let bus = EventBus(modelContext: context)

        // Request notification permission and set up delegate
        Task {
            _ = await EventBus.requestNotificationPermission()
        }
        let delegate = NotificationDelegate()
        delegate.bus = bus
        UNUserNotificationCenter.current().delegate = delegate

        bus.connect(baseURL: url, apiKey: (apiKey?.isEmpty ?? true) ? nil : apiKey)
        eventBus = bus
    }

    // MARK: - Intent Handling

    private func checkPendingIntents(bus: EventBus) {
        guard let shared = UserDefaults(suiteName: EventBus.appGroup) else { return }

        // Continue conversation intent
        if shared.bool(forKey: "intent.continueConversation") {
            shared.removeObject(forKey: "intent.continueConversation")
            if let last = bus.conversations.first {
                bus.selectConversation(last)
            }
        }

        // Pending prompt intent
        if let prompt = shared.string(forKey: "intent.pendingPrompt") {
            let timestamp = shared.double(forKey: "intent.pendingPromptTimestamp")
            // Only use if less than 60 seconds old
            if Date().timeIntervalSince1970 - timestamp < 60 {
                shared.removeObject(forKey: "intent.pendingPrompt")
                shared.removeObject(forKey: "intent.pendingPromptTimestamp")
                bus.send(prompt)
            } else {
                // Stale — just clear
                shared.removeObject(forKey: "intent.pendingPrompt")
                shared.removeObject(forKey: "intent.pendingPromptTimestamp")
            }
        }
    }

    /// Handle URL scheme (groktodash://) from intents and deeplinks.
    private func handleURL(_ url: URL, bus: EventBus) {
        switch url.host {
        case "ask":
            if let prompt = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "prompt" })?.value {
                bus.send(prompt.removingPercentEncoding ?? prompt)
            }
        case "continue":
            if let last = bus.conversations.first {
                bus.selectConversation(last)
            }
        default:
            break
        }
    }
}

// MARK: - Content View

/// Post-connection content — sidebar + chat.
struct ContentView: View {
    @Environment(EventBus.self) private var bus

    var body: some View {
        Group {
            if bus.connectionStatus == .disconnected {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Gateway Unreachable")
                        .font(.title2)
                    if let error = bus.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Retry") {
                        // Reconnect would need stored URL; handled via GatewaySettingsView
                    }
                    .buttonStyle(.bordered)
                }
                .frame(width: 400, height: 300)
            } else {
                ChatView()
            }
        }
    }
}

import AppIntents

// MARK: - Ask Hermes Intent

/// Siri/Shortcuts intent: "Ask Hermes to review my PRs"
struct AskHermesIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Hermes"
    static let description = IntentDescription(
        "Send a prompt to Hermes and open GroktoDash with the response.",
        categoryName: "Productivity"
    )
    static let openAppWhenRun = true

    @Parameter(title: "Prompt", description: "What to ask Hermes.")
    var prompt: String

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        // Write the prompt to App Group storage so the main app can pick it up
        if let shared = UserDefaults(suiteName: "group.com.groktopus.groktodash") {
            shared.set(prompt, forKey: "intent.pendingPrompt")
            shared.set(Date().timeIntervalSince1970, forKey: "intent.pendingPromptTimestamp")
        }
        return .result()
    }
}

// MARK: - Continue Conversation Intent

/// Siri/Shortcuts intent: "Continue my last conversation with Hermes"
struct ContinueConversationIntent: AppIntent {
    static let title: LocalizedStringResource = "Continue Conversation"
    static let description = IntentDescription(
        "Open your most recent conversation with Hermes.",
        categoryName: "Productivity"
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        // Signal to the main app to open the most recent conversation
        if let shared = UserDefaults(suiteName: "group.com.groktopus.groktodash") {
            shared.set(true, forKey: "intent.continueConversation")
        }
        return .result()
    }
}

// MARK: - Ask Hermes Shortcut (Shortcuts App)

/// Shortcut-only variant that returns text without opening the app.
struct AskHermesShortcut: AppIntent {
    static let title: LocalizedStringResource = "Ask Hermes (Inline)"
    static let description = IntentDescription(
        "Ask Hermes a question and get the answer as Shortcuts output.",
        categoryName: "Productivity"
    )

    @Parameter(title: "Prompt")
    var prompt: String

    @Parameter(title: "Gateway URL")
    var gatewayURL: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Signal to the app via App Group
        if let shared = UserDefaults(suiteName: "group.com.groktopus.groktodash") {
            shared.set(prompt, forKey: "intent.pendingPrompt")
            shared.set(gatewayURL, forKey: "intent.gatewayURL")
            shared.set(Date().timeIntervalSince1970, forKey: "intent.pendingPromptTimestamp")
        }
        return .result(value: "Prompt sent: \(prompt)")
    }
}

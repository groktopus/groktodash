import AppIntents

/// Stub — "Ask Hermes" Siri intent (M4).
struct AskHermesIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Hermes"

    @Parameter(title: "Prompt")
    var prompt: String

    func perform() async throws -> some IntentResult {
        // M4: open app with prompt pre-filled
        return .result()
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Ask Hermes to \(\.$prompt)")
    }
}

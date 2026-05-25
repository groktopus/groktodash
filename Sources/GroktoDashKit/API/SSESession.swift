import Foundation

/// Represents a single event from the Hermes Runs SSE stream.
public enum RunEvent: Sendable {
    /// Streaming text delta — append to display
    case textDelta(runId: String, text: String)

    /// Reasoning/thinking output
    case reasoningAvailable(runId: String, text: String)

    /// Tool execution began
    case toolStarted(runId: String, tool: String, preview: String)

    /// Tool execution completed
    case toolCompleted(runId: String, tool: String, duration: Double, isError: Bool)

    /// Approval required for a tool call
    case approvalRequired(runId: String, tool: String, choices: [String])

    /// Run completed successfully
    case runCompleted(runId: String, output: String)

    /// Run was cancelled
    case runCancelled(runId: String)

    /// Run failed with error
    case runFailed(runId: String, error: String)

    /// Unknown event type — preserved for forward compatibility
    case unknown(eventType: String)
}

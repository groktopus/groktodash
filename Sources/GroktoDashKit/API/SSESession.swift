import Foundation

// MARK: - RunEvent

/// Represents a single event from the Hermes Runs SSE stream.
public enum RunEvent: Sendable, Equatable {
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

// MARK: - SSESession

/// Pure Swift SSE (Server-Sent Events) byte-stream parser.
///
/// Parses an SSE stream from the Hermes API Server, producing ``RunEvent``
/// values via an `AsyncStream`. Handles both:
/// - **Runs API SSE** — `event: message.delta`, `event: tool.started`, etc.
/// - **Legacy Chat Completions SSE** — `data: {"choices":[...]}` and
///   `event: hermes.tool.progress`
///
/// Zero dependencies.  Works on `URLSession.bytes` line sequences.
public struct SSESession: Sendable {

    /// Parse an SSE byte-stream from a URLSession async line sequence.
    ///
    /// - Parameter lines: An `AsyncSequence` of `String` lines from
    ///   `URLSession.bytes(for:).lines`.
    /// - Returns: An `AsyncStream` of ``RunEvent`` values.
    public static func parse<S: AsyncSequence & Sendable>(
        _ lines: S
    ) -> AsyncStream<RunEvent> where S.Element == String {
        AsyncStream { continuation in
            let task = Task {
                var currentEvent: String?  // accumulated "event:" value
                var currentData = ""       // accumulated "data:" value (multiline)

                for try await line in lines {
                    // SSE spec: blank line (empty or just "\r") dispatches the event
                    guard !line.isEmpty, line != "\r" else {
                        if let dataStr = currentData.nilIfEmpty {
                            let event = parseEvent(
                                eventType: currentEvent,
                                data: dataStr
                            )
                            continuation.yield(event)
                        }
                        currentEvent = nil
                        currentData = ""
                        continue
                    }

                    // SSE spec: lines starting with ':' are comments
                    if line.hasPrefix(":") { continue }

                    if line.hasPrefix("event:") {
                        currentEvent = String(line.dropFirst(6).trimmingCharacters(in: .whitespaces))
                    } else if line.hasPrefix("data:") {
                        let value = String(line.dropFirst(5))
                        let trimmed = value.hasPrefix(" ") ? String(value.dropFirst()) : value
                        if currentData.isEmpty {
                            currentData = trimmed
                        } else {
                            currentData += "\n" + trimmed
                        }
                    }
                }

                // Flush any remaining event at EOF
                if let dataStr = currentData.nilIfEmpty {
                    let event = parseEvent(eventType: currentEvent, data: dataStr)
                    continuation.yield(event)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Parse a captured data line into a ``RunEvent``.
    private static func parseEvent(eventType: String?, data: String) -> RunEvent {
        // Legacy chat completions SSE: data: {"choices": [...], ...}
        if eventType == nil && data.hasPrefix("{") {
            if let parsed = parseChatCompletionData(data) {
                return parsed
            }
        }

        // Legacy chat completions tool progress: event: hermes.tool.progress
        if eventType == "hermes.tool.progress" {
            return parseToolProgress(data)
        }

        // [DONE] sentinel — emitted at end of chat completions stream
        if data == "[DONE]" {
            return .unknown(eventType: "done")
        }

        // Runs API events — parse JSON payloads
        guard let jsonData = data.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let event = obj["event"] as? String,
              let runId = obj["run_id"] as? String else {
            return .unknown(eventType: eventType ?? String(data.prefix(40)))
        }

        switch event {
        case "message.delta":
            let text = (obj["delta"] as? String) ?? ""
            return .textDelta(runId: runId, text: text)

        case "reasoning.available":
            let text = (obj["text"] as? String) ?? ""
            return .reasoningAvailable(runId: runId, text: text)

        case "tool.started":
            let tool = (obj["tool"] as? String) ?? "unknown"
            let preview = (obj["preview"] as? String) ?? tool
            return .toolStarted(runId: runId, tool: tool, preview: preview)

        case "tool.completed":
            let tool = (obj["tool"] as? String) ?? "unknown"
            let duration = (obj["duration"] as? Double) ?? 0
            let isError = (obj["error"] as? Bool) ?? false
            return .toolCompleted(runId: runId, tool: tool, duration: duration, isError: isError)

        case "approval.request":
            let tool = (obj["tool"] as? String) ?? "unknown"
            let choices = (obj["choices"] as? [String]) ?? ["once", "session", "always", "deny"]
            return .approvalRequired(runId: runId, tool: tool, choices: choices)

        case "run.completed":
            let output = (obj["output"] as? String) ?? ""
            return .runCompleted(runId: runId, output: output)

        case "run.cancelled":
            return .runCancelled(runId: runId)

        case "run.failed":
            let error = (obj["error"] as? String) ?? "Unknown error"
            return .runFailed(runId: runId, error: error)

        default:
            return .unknown(eventType: event)
        }
    }

    /// Parse legacy chat completions SSE data into a ``RunEvent``.
    ///
    /// Handles both the `data: [DONE]` sentinel and the
    /// `data: {"choices": [{"delta": {"content": "..."}}]}` text chunks.
    private static func parseChatCompletionData(_ dataStr: String) -> RunEvent? {
        guard let jsonData = dataStr.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String else {
            return nil
        }
        // Chat completions don't carry a run_id — use "legacy" placeholder
        return .textDelta(runId: "legacy", text: content)
    }

    /// Parse `hermes.tool.progress` event data.
    private static func parseToolProgress(_ dataStr: String) -> RunEvent {
        guard let jsonData = dataStr.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return .unknown(eventType: "hermes.tool.progress")
        }
        let tool = (obj["tool"] as? String) ?? "unknown"
        let status = (obj["status"] as? String) ?? "unknown"
        let toolCallId = obj["toolCallId"] as? String ?? ""

        switch status {
        case "running":
            let label = (obj["label"] as? String) ?? tool
            return .toolStarted(runId: toolCallId, tool: tool, preview: label)
        case "completed":
            return .toolCompleted(runId: toolCallId, tool: tool, duration: 0, isError: false)
        default:
            return .unknown(eventType: "hermes.tool.progress.\(status)")
        }
    }
}

// MARK: - String Helper

extension String {
    /// Returns nil if the string is empty (after trimming whitespace).
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}

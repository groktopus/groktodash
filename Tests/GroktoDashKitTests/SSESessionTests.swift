import Foundation
import Testing
import GroktoDashKit

// MARK: - Helpers

/// Create an AsyncSequence of SSE lines from a raw byte stream string.
func sseLines(from raw: String) -> AsyncStream<String> {
    AsyncStream { continuation in
        let lines = raw.components(separatedBy: "\n")
        for line in lines {
            if line.hasSuffix("\r") {
                continuation.yield(String(line.dropLast()))
            } else {
                continuation.yield(line)
            }
        }
        continuation.finish()
    }
}

/// Collect all events from parsing an SSE stream.
func parseSSE(_ raw: String) async -> [RunEvent] {
    var events: [RunEvent] = []
    let stream = SSESession.parse(sseLines(from: raw))
    for await event in stream {
        events.append(event)
    }
    return events
}

// MARK: - Runs API Event Tests

@Suite struct SSERunsAPITests {
    @Test func testMessageDelta() async throws {
        let raw = """
        event: message.delta
        data: {"event":"message.delta","run_id":"run_abc","delta":"Hello"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .textDelta(runId: "run_abc", text: "Hello"))
    }

    @Test func testReasoningAvailable() async throws {
        let raw = """
        event: reasoning.available
        data: {"event":"reasoning.available","run_id":"run_abc","text":"Let me think..."}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .reasoningAvailable(runId: "run_abc", text: "Let me think..."))
    }

    @Test func testToolStarted() async throws {
        let raw = """
        event: tool.started
        data: {"event":"tool.started","run_id":"run_abc","tool":"search","preview":"Searching..."}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .toolStarted(runId: "run_abc", tool: "search", preview: "Searching..."))
    }

    @Test func testToolCompleted() async throws {
        let raw = """
        event: tool.completed
        data: {"event":"tool.completed","run_id":"run_abc","tool":"search","duration":0.42,"error":false}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .toolCompleted(runId: "run_abc", tool: "search", duration: 0.42, isError: false))
    }

    @Test func testToolCompletedError() async throws {
        let raw = """
        event: tool.completed
        data: {"event":"tool.completed","run_id":"run_abc","tool":"terminal","duration":0.1,"error":true}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .toolCompleted(runId: "run_abc", tool: "terminal", duration: 0.1, isError: true))
    }

    @Test func testApprovalRequired() async throws {
        let raw = """
        event: approval.request
        data: {"event":"approval.request","run_id":"run_abc","tool":"terminal","choices":["once","session","always","deny"]}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .approvalRequired(runId: "run_abc", tool: "terminal", choices: ["once", "session", "always", "deny"]))
    }

    @Test func testRunCompleted() async throws {
        let raw = """
        event: run.completed
        data: {"event":"run.completed","run_id":"run_abc","output":"All done!"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .runCompleted(runId: "run_abc", output: "All done!"))
    }

    @Test func testRunCancelled() async throws {
        let raw = """
        event: run.cancelled
        data: {"event":"run.cancelled","run_id":"run_abc"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .runCancelled(runId: "run_abc"))
    }

    @Test func testRunFailed() async throws {
        let raw = """
        event: run.failed
        data: {"event":"run.failed","run_id":"run_abc","error":"Connection timeout"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .runFailed(runId: "run_abc", error: "Connection timeout"))
    }
}

// MARK: - Legacy Chat Completions Tests

@Suite struct SSELegacyTests {
    @Test func testChatCompletionDelta() async throws {
        let raw = """
        data: {"id":"cmpl_123","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .textDelta(runId: "legacy", text: "Hello"))
    }

    @Test func testHermesToolProgressRunning() async throws {
        let raw = """
        event: hermes.tool.progress
        data: {"tool":"search","emoji":"🔍","label":"Searching...","toolCallId":"tc_123","status":"running"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .toolStarted(runId: "tc_123", tool: "search", preview: "Searching..."))
    }

    @Test func testHermesToolProgressCompleted() async throws {
        let raw = """
        event: hermes.tool.progress
        data: {"tool":"search","toolCallId":"tc_123","status":"completed"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .toolCompleted(runId: "tc_123", tool: "search", duration: 0, isError: false))
    }

    @Test func testDoneSentinel() async throws {
        let raw = """
        data: [DONE]

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .unknown(eventType: "done"))
    }
}

// MARK: - Multiline & Commentary Tests

@Suite struct SSEMultiLineTests {
    @Test func testMultilineData() async throws {
        // Multiline data is concatenated with newlines
        let raw = """
        event: message.delta
        data: {"event":"message.delta","run_id":"run_abc",
        data: "delta":"Hello world"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        // Multiline joins with \n between data lines
        #expect(events[0] == .textDelta(runId: "run_abc", text: "Hello world"))
    }

    @Test func testCommentLinesIgnored() async throws {
        let raw = """
        : this is a comment
        event: message.delta
        : another comment
        data: {"event":"message.delta","run_id":"run_abc","delta":"ok"}
        : trailing comment

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .textDelta(runId: "run_abc", text: "ok"))
    }

    @Test func testMultipleEvents() async throws {
        let raw = """
        event: message.delta
        data: {"event":"message.delta","run_id":"run_abc","delta":"Hello"}

        event: tool.started
        data: {"event":"tool.started","run_id":"run_abc","tool":"search","preview":"Searching..."}

        event: tool.completed
        data: {"event":"tool.completed","run_id":"run_abc","tool":"search","duration":0.5,"error":false}

        event: run.completed
        data: {"event":"run.completed","run_id":"run_abc","output":"Done!"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 4)
        #expect(events[0] == .textDelta(runId: "run_abc", text: "Hello"))
        #expect(events[1] == .toolStarted(runId: "run_abc", tool: "search", preview: "Searching..."))
        #expect(events[2] == .toolCompleted(runId: "run_abc", tool: "search", duration: 0.5, isError: false))
        #expect(events[3] == .runCompleted(runId: "run_abc", output: "Done!"))
    }

    @Test func testEmptyStream() async throws {
        let events = await parseSSE("")
        #expect(events.isEmpty)
    }
}

// MARK: - Edge Cases

@Suite struct SSEEdgeCaseTests {
    @Test func testUnknownEventType() async throws {
        let raw = """
        event: some.future.event
        data: {"event":"some.future.event","run_id":"run_abc"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .unknown(eventType: "some.future.event"))
    }

    @Test func testMalformedJSON() async throws {
        let raw = """
        event: message.delta
        data: {not valid json}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        // Falls through to unknown with raw prefix
        #expect(events[0] == .unknown(eventType: "message.delta"))
    }

    @Test func testSpacingInEventLine() async throws {
        let raw = """
        event: message.delta
        data: {"event":"message.delta","run_id":"run_abc","delta":"trimmed"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .textDelta(runId: "run_abc", text: "trimmed"))
    }

    @Test func testDataWithLeadingSpace() async throws {
        let raw = """
        event: message.delta
        data:  {"event":"message.delta","run_id":"run_abc","delta":"spaced"}

        """
        let events = await parseSSE(raw)
        #expect(events.count == 1)
        #expect(events[0] == .textDelta(runId: "run_abc", text: "spaced"))
    }
}

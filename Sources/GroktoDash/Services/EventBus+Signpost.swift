import os.signpost

/// Performance instrumentation for EventBus streaming.
///
/// Uses os_signpost for zero-overhead profiling in Instruments.
/// All signposts are compile-time conditionals — stripped from release builds.
extension EventBus {

    // MARK: - Signpost Log

    private static let signpostLog = OSLog(
        subsystem: "com.groktopus.groktodash",
        category: .pointsOfInterest
    )

    // MARK: - Streaming Latency

    /// Record the start of a streaming run for latency measurement.
    func signpostRunStart(runId: String) {
        os_signpost(.begin, log: Self.signpostLog, name: "Run Streaming",
                    "Run %{public}s started", runId)
    }

    /// Record a text delta event for latency tracking.
    func signpostDeltaReceived(runId: String) {
        os_signpost(.event, log: Self.signpostLog, name: "Text Delta",
                    "Delta received for run %{public}s", runId)
    }

    /// Record the end of a streaming run.
    func signpostRunEnd(runId: String) {
        os_signpost(.end, log: Self.signpostLog, name: "Run Streaming",
                    "Run %{public}s completed", runId)
    }
}

// MARK: - Signpost Senders (called from handleEvent)

extension EventBus {
    /// Call before creating a run.
    func instrumentRunStart() {
        guard let runId = activeRunId else { return }
        signpostRunStart(runId: runId)
    }

    /// Call on each text delta.
    func instrumentDelta() {
        guard let runId = activeRunId else { return }
        signpostDeltaReceived(runId: runId)
    }

    /// Call on run completion.
    func instrumentRunEnd() {
        guard let runId = activeRunId else { return }
        signpostRunEnd(runId: runId)
    }
}

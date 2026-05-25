import Foundation
import SwiftData
import Observation
import GroktoDashKit

/// Central event dispatcher for GroktoDash.
///
/// Receives SSE events from HermesClient, routes them to SwiftUI state,
/// and persists conversations to SwiftData.  The app's single source of truth.
@MainActor
@Observable
public final class EventBus {
    // MARK: - Published State

    /// Current conversation — shown in the chat view.
    public var currentConversation: Conversation?

    /// All conversations for the sidebar.
    public var conversations: [Conversation] = []

    /// Active Hermes client (nil when disconnected).
    public var client: HermesClient?

    /// Whether a run is currently active.
    public var isRunning = false

    /// The current run ID (if active).
    public var activeRunId: String?

    /// Streaming message being built (shown live in the chat view).
    public var streamingMessage: Message?

    /// Tool calls from the current run (shown in the timeline).
    public var toolCalls: [ToolCall] = []

    /// Pending approval (shown as a sheet/notification).
    public var pendingApproval: (runId: String, tool: String, choices: [String])?

    /// Connection status.
    public enum ConnectionStatus { case disconnected, connecting, connected }
    public var connectionStatus: ConnectionStatus = .disconnected

    /// Error state.
    public var errorMessage: String?

    // MARK: - Internal

    private let modelContext: ModelContext
    private var runTask: Task<Void, Never>?

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchConversations()
    }

    // MARK: - Connection

    public func connect(baseURL: URL, apiKey: String? = nil) {
        client = HermesClient(baseURL: baseURL, apiKey: apiKey)
        connectionStatus = .connecting

        Task {
            do {
                let healthy = try await client!.checkHealth()
                connectionStatus = healthy ? .connected : .disconnected
                if !healthy { errorMessage = "Gateway unreachable" }
            } catch {
                connectionStatus = .disconnected
                errorMessage = error.localizedDescription
            }
        }
    }

    public func disconnect() {
        runTask?.cancel()
        client = nil
        connectionStatus = .disconnected
        isRunning = false
    }

    // MARK: - Conversations

    public func newConversation() {
        let conv = Conversation(title: "New conversation")
        modelContext.insert(conv)
        try? modelContext.save()
        currentConversation = conv
        toolCalls = []
        streamingMessage = nil
        pendingApproval = nil
    }

    public func selectConversation(_ conv: Conversation) {
        currentConversation = conv
        toolCalls = conv.messages.flatMap { $0.toolCalls }
        streamingMessage = nil
        pendingApproval = nil
    }

    public func deleteConversation(_ conv: Conversation) {
        modelContext.delete(conv)
        try? modelContext.save()
        if currentConversation?.id == conv.id {
            currentConversation = nil
        }
        fetchConversations()
    }

    private func fetchConversations() {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        conversations = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Send Message

    public func send(_ prompt: String) {
        guard let client, connectionStatus == .connected, !isRunning else { return }

        // Ensure we have a conversation
        if currentConversation == nil { newConversation() }
        guard let conv = currentConversation else { return }

        // Create user message
        let userMsg = Message(role: .user, content: prompt, conversation: conv)
        modelContext.insert(userMsg)

        // Create streaming Hermes message placeholder
        let hermesMsg = Message(role: .hermes, content: "", conversation: conv)
        modelContext.insert(hermesMsg)
        streamingMessage = hermesMsg
        toolCalls = []
        pendingApproval = nil

        conv.updatedAt = Date()
        try? modelContext.save()

        // Start the run
        isRunning = true
        errorMessage = nil

        runTask = Task {
            do {
                let runRequest = CreateRunRequest(prompt: prompt)
                let run = try await client.createRun(runRequest)
                activeRunId = run.id

                let runObj = Run(runId: run.id, status: .running)
                runObj.conversation = conv
                modelContext.insert(runObj)

                // Stream SSE events
                let eventStream = client.events(for: run.id)
                for await event in eventStream {
                    if Task.isCancelled { break }
                    handleEvent(event, messageId: hermesMsg.id)
                }

                // Mark streaming complete
                hermesMsg.isStreaming = false
                conv.updatedAt = Date()
                try? modelContext.save()
                fetchConversations()

            } catch {
                errorMessage = error.localizedDescription
                hermesMsg.isStreaming = false
                try? modelContext.save()
            }

            isRunning = false
            activeRunId = nil
            streamingMessage = nil
        }
    }

    public func stopRun() {
        guard let runId = activeRunId, let client else { return }
        runTask?.cancel()
        Task {
            try? await client.stopRun(runId: runId)
        }
        isRunning = false
        streamingMessage?.isStreaming = false
    }

    // MARK: - Approval

    public func resolveApproval(choice: ApprovalRequest.Choice) {
        guard let runId = activeRunId, let client else { return }
        pendingApproval = nil
        Task {
            try? await client.resolveApproval(runId: runId, choice: choice)
        }
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: RunEvent, messageId: UUID) {
        switch event {
        case .textDelta(_, let text):
            streamingMessage?.content += text

        case .reasoningAvailable(_, _):
            // Reasoning can be shown in an expandable panel in the UI
            break

        case .toolStarted(let runId, let tool, let preview):
            let tc = ToolCall(toolCallId: "\(runId)-\(tool)", toolName: tool, preview: preview, status: .running)
            tc.message = streamingMessage
            modelContext.insert(tc)
            toolCalls.append(tc)

        case .toolCompleted(_, let tool, let duration, let isError):
            if let tc = toolCalls.first(where: { $0.toolName == tool && $0.status == .running }) {
                tc.status = isError ? .error : .completed
                tc.duration = duration
            }

        case .approvalRequired(let runId, let tool, let choices):
            pendingApproval = (runId: runId, tool: tool, choices: choices)

        case .runCompleted(_, let output):
            streamingMessage?.content = output.isEmpty ? streamingMessage?.content ?? "" : output

        case .runFailed(_, let error):
            errorMessage = error

        case .runCancelled, .unknown:
            break
        }
    }
}

import Foundation
import SwiftData

// MARK: - Conversation

@Model
public final class Conversation {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    public var messages: [Message] = []

    @Relationship(deleteRule: .cascade, inverse: \Run.conversation)
    public var runs: [Run] = []

    public init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Message

@Model
public final class Message {
    public enum Role: String, Codable {
        case user
        case hermes
    }

    public var id: UUID
    public var roleRaw: String
    public var content: String
    public var timestamp: Date
    public var isStreaming: Bool

    public var conversation: Conversation?

    @Relationship(deleteRule: .cascade, inverse: \ToolCall.message)
    public var toolCalls: [ToolCall] = []

    public var role: Role {
        get { Role(rawValue: roleRaw) ?? .hermes }
        set { roleRaw = newValue.rawValue }
    }

    public init(role: Role, content: String = "", conversation: Conversation? = nil) {
        self.id = UUID()
        self.roleRaw = role.rawValue
        self.content = content
        self.timestamp = Date()
        self.isStreaming = role == .hermes
        self.conversation = conversation
    }
}

// MARK: - ToolCall

@Model
public final class ToolCall {
    public enum Status: String, Codable {
        case running
        case completed
        case error
    }

    public var toolCallId: String
    public var toolName: String
    public var preview: String
    public var statusRaw: String
    public var duration: Double?
    public var createdAt: Date

    public var message: Message?

    public var status: Status {
        get { Status(rawValue: statusRaw) ?? .running }
        set { statusRaw = newValue.rawValue }
    }

    public init(toolCallId: String, toolName: String, preview: String, status: Status = .running) {
        self.toolCallId = toolCallId
        self.toolName = toolName
        self.preview = preview
        self.statusRaw = status.rawValue
        self.createdAt = Date()
    }
}

// MARK: - Run

@Model
public final class Run {
    public enum RunStatus: String, Codable {
        case queued
        case running
        case completed
        case failed
        case cancelled
        case waitingForApproval
    }

    public var runId: String
    public var statusRaw: String
    public var output: String?
    public var inputTokens: Int?
    public var outputTokens: Int?
    public var createdAt: Date

    public var conversation: Conversation?

    public var status: RunStatus {
        get { RunStatus(rawValue: statusRaw) ?? .queued }
        set { statusRaw = newValue.rawValue }
    }

    public init(runId: String, status: RunStatus = .queued) {
        self.runId = runId
        self.statusRaw = status.rawValue
        self.createdAt = Date()
    }
}

// MARK: - Container

/// SwiftData model container configuration for GroktoDash.
public enum DataStore {
    public static let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: Conversation.self, Message.self, ToolCall.self, Run.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}

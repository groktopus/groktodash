import Foundation

// MARK: - Run Models

/// Represents a Hermes Agent run as returned by POST /v1/runs
public struct HermesRun: Codable, Sendable {
    public let id: String
    public let status: RunStatus
    public let createdAt: Date?
    public let updatedAt: Date?
    public let output: String?
    public let usage: Usage?

    public init(id: String, status: RunStatus, createdAt: Date? = nil, updatedAt: Date? = nil, output: String? = nil, usage: Usage? = nil) {
        self.id = id
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.output = output
        self.usage = usage
    }
}

public enum RunStatus: String, Codable, Sendable {
    case queued
    case started
    case running
    case completed
    case failed
    case cancelled
    case waitingForApproval = "waiting_for_approval"
}

public struct Usage: Codable, Sendable {
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let totalTokens: Int?

    public init(inputTokens: Int? = nil, outputTokens: Int? = nil, totalTokens: Int? = nil) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
    }

    enum CodingKeys: String, CodingKey {
        case inputTokens = "prompt_tokens"
        case outputTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Run Request

public struct CreateRunRequest: Codable {
    public let prompt: String
    public let instructions: String?
    public let sessionId: String?
    public let model: String?

    enum CodingKeys: String, CodingKey {
        case prompt
        case instructions
        case sessionId = "session_id"
        case model
    }

    public init(prompt: String, instructions: String? = nil, sessionId: String? = nil, model: String? = nil) {
        self.prompt = prompt
        self.instructions = instructions
        self.sessionId = sessionId
        self.model = model
    }
}

// MARK: - Run Status Response

public struct RunStatusResponse: Codable, Sendable {
    public let object: String
    public let runId: String
    public let status: String
    public let createdAt: Double?
    public let updatedAt: Double?

    enum CodingKeys: String, CodingKey {
        case object
        case runId = "run_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Approval

public struct ApprovalRequest: Codable, Sendable {
    public enum Choice: String, Codable, Sendable {
        case once
        case session
        case always
        case deny
    }

    public let choice: Choice

    public init(choice: Choice) {
        self.choice = choice
    }
}

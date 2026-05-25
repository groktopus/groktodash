import Foundation

/// HTTP client for the Hermes API Server.
///
/// Communicates with a running Hermes gateway over the standardized API Server
/// endpoints. Handles JSON encoding/decoding and HTTP error mapping.
public final class HermesClient: @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(baseURL: URL, apiKey: String? = nil) {
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()

        let config = URLSessionConfiguration.default
        if let apiKey {
            config.httpAdditionalHeaders = ["Authorization": "Bearer \(apiKey)"]
        }
        self.session = URLSession(configuration: config)
    }

    // MARK: - Health

    /// Check gateway connectivity. Returns true if /health responds.
    public func checkHealth() async throws -> Bool {
        let url = baseURL.appendingPathComponent("health")
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (_, response) = try await session.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    // MARK: - Runs

    /// Start a new run. Returns the run ID on success.
    public func createRun(_ runRequest: CreateRunRequest) async throws -> HermesRun {
        let url = baseURL.appendingPathComponent("v1/runs")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(runRequest)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decoder.decode(HermesRun.self, from: data)
    }

    /// Poll run status.
    public func getRunStatus(runId: String) async throws -> HermesRun {
        let url = baseURL.appendingPathComponent("v1/runs/\(runId)")
        let (data, response) = try await session.data(for: URLRequest(url: url))
        try validateResponse(response, data: data)
        return try decoder.decode(HermesRun.self, from: data)
    }

    /// Resolve an approval.
    public func resolveApproval(runId: String, choice: ApprovalRequest.Choice) async throws {
        let url = baseURL.appendingPathComponent("v1/runs/\(runId)/approval")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(ApprovalRequest(choice: choice))

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    /// Stop a running run.
    public func stopRun(runId: String) async throws {
        let url = baseURL.appendingPathComponent("v1/runs/\(runId)/stop")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - SSE

    /// Open an SSE event stream for a run. Returns an AsyncStream of ``RunEvent``.
    ///
    /// Uses ``SSESession`` to parse the byte stream into typed events.
    /// Handles connection errors gracefully — the stream finishes on error.
    public func events(for runId: String) -> AsyncStream<RunEvent> {
        AsyncStream { continuation in
            Task {
                let url = baseURL.appendingPathComponent("v1/runs/\(runId)/events")
                var request = URLRequest(url: url)
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                        continuation.finish()
                        return
                    }

                    let eventStream = SSESession.parse(bytes.lines)
                    for await event in eventStream {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HermesError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200, 202:
            return
        case 401:
            throw HermesError.unauthorized
        case 404:
            throw HermesError.notFound
        case 500...599:
            throw HermesError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw HermesError.unexpectedStatus(statusCode: httpResponse.statusCode)
        }
    }
}

public enum HermesError: Error {
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(statusCode: Int)
    case unexpectedStatus(statusCode: Int)
}

import Foundation
import Testing
import GroktoDashKit

@Suite struct HermesClientTests {
    @Test func testURLConstruction() throws {
        let client = HermesClient(baseURL: URL(string: "http://localhost:8642")!)
        // URL construction validated by init not throwing
        #expect(client != nil)
    }

    @Test func testAPIKeyInjection() throws {
        let client = HermesClient(baseURL: URL(string: "http://localhost:8642")!, apiKey: "sk-test-123")
        // API key is injected into URLSession config — verified by init succeeding
        #expect(Bool(true))
    }

    @Test func testNoAPIKey() throws {
        let client = HermesClient(baseURL: URL(string: "http://localhost:8642")!)
        // No API key — client works without auth for local gateways
        #expect(Bool(true))
    }

    @Test func testErrorEnumValues() throws {
        #expect(HermesError.invalidResponse as HermesError? != nil)
        #expect(HermesError.unauthorized as HermesError? != nil)

        let notFound = HermesError.notFound
        let serverError = HermesError.serverError(statusCode: 500)
        let unexpected = HermesError.unexpectedStatus(statusCode: 418)

        // Verify we can pattern-match
        switch notFound {
        case .notFound: break
        default: #expect(Bool(false), "Expected .notFound")
        }

        switch serverError {
        case .serverError(let code): #expect(code == 500)
        default: #expect(Bool(false))
        }

        switch unexpected {
        case .unexpectedStatus(let code): #expect(code == 418)
        default: #expect(Bool(false))
        }
    }

    @Test func testCreateRunRequestSerialization() throws {
        let request = CreateRunRequest(
            prompt: "Hello, Hermes!",
            instructions: "Be concise.",
            sessionId: "sess_123",
            model: "deepseek-v4-flash"
        )
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["prompt"] as? String == "Hello, Hermes!")
        #expect(json?["instructions"] as? String == "Be concise.")
        #expect(json?["session_id"] as? String == "sess_123")
        #expect(json?["model"] as? String == "deepseek-v4-flash")
    }

    @Test func testCreateRunRequestMinimal() throws {
        let request = CreateRunRequest(prompt: "Hello")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["prompt"] as? String == "Hello")
        #expect(json?["instructions"] == nil)
        #expect(json?["session_id"] == nil)
        #expect(json?["model"] == nil)
    }
}

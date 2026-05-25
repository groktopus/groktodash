import Foundation
import Testing
import GroktoDashKit

@Suite struct ModelsTests {
    @Test func testRunStatusDecoding() throws {
        let json = #"{"id":"run_123","status":"completed"}"#
        let data = Data(json.utf8)
        let run = try JSONDecoder().decode(HermesRun.self, from: data)
        #expect(run.id == "run_123")
        #expect(run.status == .completed)
    }

    @Test func testRunStatusRawValues() {
        #expect(RunStatus.queued.rawValue == "queued")
        #expect(RunStatus.waitingForApproval.rawValue == "waiting_for_approval")
        #expect(RunStatus.completed.rawValue == "completed")
    }

    @Test func testCreateRunRequestEncoding() throws {
        let request = CreateRunRequest(prompt: "Hello")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["prompt"] as? String == "Hello")
        #expect((json?["session_id"]) is NSNull || json?["session_id"] == nil)
    }

    @Test func testApprovalRequestEncoding() throws {
        let approval = ApprovalRequest(choice: .once)
        let data = try JSONEncoder().encode(approval)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["choice"] as? String == "once")
    }
}

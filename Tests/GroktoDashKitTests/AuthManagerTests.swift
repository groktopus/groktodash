import Foundation
import Testing
import GroktoDashKit

@Suite struct AuthManagerTests {
    @Test func testInit() throws {
        let auth = AuthManager()
        #expect(type(of: auth) == AuthManager.self)
    }

    @Test func testGatewayURLRoundTrip() throws {
        let auth = AuthManager()
        let testURL = "http://test.local:8642"
        try auth.saveGatewayURL(testURL)
        let retrieved = auth.getGatewayURL()
        #expect(retrieved == testURL)
    }

    @Test func testAPIKeyRoundTrip() throws {
        let auth = AuthManager()
        let testKey = "sk-tes...c123"
        try auth.saveAPIKey(testKey)
        let retrieved = auth.getAPIKey()
        #expect(retrieved == testKey)
    }

    @Test func testAuthErrorDescription() throws {
        let error = AuthError.keychainError(status: -25299)
        switch error {
        case .keychainError(let status):
            #expect(status == -25299)
        }
    }
}

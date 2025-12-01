@testable import backend
import XCTVapor
import XCTest

final class AppTests: XCTestCase {
    func testHealthCheck() async throws {
        try await withTestApp { app in
            try await app.test(.GET, "health") { res async in
                XCTAssertEqual(res.status, .ok)
            }
        }
    }
}

// MARK: - Shared helpers

func withTestApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    try await configure(app)
    do {
        try await test(app)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

@discardableResult
func registerUser(app: Application, email: String, password: String) async throws -> LoginResponse {
    var responseBody: LoginResponse?
    try await app.test(.POST, "auth/register", beforeRequest: { req in
        try req.content.encode(RegisterRequest(
            firstName: "Test",
            lastName: "User",
            email: email,
            password: password,
            phone: "0602030405",
            department: "IT",
            position: "QA"
        ))
    }) { res async throws in
        XCTAssertEqual(res.status, .ok)
        responseBody = try res.content.decode(LoginResponse.self)
    }
    return responseBody!
}

func randomTestEmail(prefix: String) -> String {
    let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    return "\(prefix).\(uuid)@company.com"
}

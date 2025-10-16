@testable import backend
import XCTVapor
import XCTest

final class AppTests: XCTestCase {
    func testHealthCheck() async throws {
        let app = try await Application.make(.testing)
        defer { app.shutdown() }
        
        try await configure(app)
        
        try await app.test(.GET, "health") { res async in
            XCTAssertEqual(res.status, .ok)
        }
    }
}

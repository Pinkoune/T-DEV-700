@testable import backend
import XCTVapor
import XCTest

final class AppTests: XCTestCase {
    func testHealthCheck() async throws {
        let app = try await Application.make(.testing)
        
        do {
            try await configure(app)
            
            try await app.test(.GET, "health") { res async in
                XCTAssertEqual(res.status, .ok)
            }
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        
        try await app.asyncShutdown()
    }
}
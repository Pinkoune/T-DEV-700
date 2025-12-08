@testable import backend
import XCTVapor
import XCTest

final class JWTAuthMiddlewareTests: XCTestCase {
    
    func testRequestWithoutTokenReturnsUnauthorized() async throws {
        try await withTestApp { app in
            try await app.test(.GET, "users/\(UUID())", beforeRequest: { req in
                // No token
            }) { res async in
                XCTAssertEqual(res.status, .unauthorized)
            }
        }
    }
    
    func testRequestWithInvalidTokenReturnsUnauthorized() async throws {
        try await withTestApp { app in
            try await app.test(.GET, "users/\(UUID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: "invalid.token.here")
            }) { res async in
                XCTAssertEqual(res.status, .unauthorized)
            }
        }
    }
    
    func testRequestWithMalformedTokenReturnsUnauthorized() async throws {
        try await withTestApp { app in
            try await app.test(.GET, "users/\(UUID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: "not-a-jwt")
            }) { res async in
                XCTAssertEqual(res.status, .unauthorized)
            }
        }
    }
    
    func testRequestWithValidTokenSucceeds() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "jwtvalid")
            
            try await app.test(.GET, "users/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async in
                XCTAssertEqual(res.status, .ok)
            }
        }
    }
    
    func testRequestWithDeactivatedUserReturnsUnauthorized() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "jwtdeactivated")
            
            let user = try await User.find(employee.id, on: app.db)
            user?.isActive = false
            try await user?.save(on: app.db)
            
            try await app.test(.GET, "users/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async in
                XCTAssertEqual(res.status, .unauthorized)
            }
        }
    }
    
    func testEmptyBearerTokenReturnsUnauthorized() async throws {
        try await withTestApp { app in
            try await app.test(.GET, "users/\(UUID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: "")
            }) { res async in
                XCTAssertEqual(res.status, .unauthorized)
            }
        }
    }
}

@testable import backend
import XCTVapor
import XCTest

final class AuthControllerTests: XCTestCase {
    func testRegisterReturnsTokenAndUser() async throws {
        try await withTestApp { app in
            let email = randomTestEmail(prefix: "register")
            let password = "StrongPass1!"
            
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(RegisterRequest(
                    firstName: "Test",
                    lastName: "User",
                    email: email,
                    password: password,
                    phone: "0601020304",
                    department: "IT",
                    position: "QA"
                ))
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let body = try res.content.decode(LoginResponse.self)
                XCTAssertTrue(body.success)
                XCTAssertEqual(body.user.email, email)
                XCTAssertFalse(body.token.isEmpty)
            }
        }
    }
    
    func testLoginWithRegisteredUser() async throws {
        try await withTestApp { app in
            let email = randomTestEmail(prefix: "login")
            let password = "AnotherPass1!"
            
            _ = try await registerUser(app: app, email: email, password: password)
            
            try await app.test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode(LoginRequest(email: email, password: password))
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let body = try res.content.decode(LoginResponse.self)
                XCTAssertEqual(body.user.email, email)
                XCTAssertFalse(body.token.isEmpty)
            }
        }
    }
    
    func testRegisterRejectsBlockedDomain() async throws {
        try await withTestApp { app in
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(RegisterRequest(
                    firstName: "Test",
                    lastName: "User",
                    email: "blocked@example.com",
                    password: "StrongPass1!",
                    phone: "0601020304",
                    department: "IT",
                    position: "QA"
                ))
            }) { res async throws in
                XCTAssertEqual(res.status, .forbidden)
            }
        }
    }
    
    func testRegisterDuplicateEmailFails() async throws {
        try await withTestApp { app in
            let email = randomTestEmail(prefix: "duplicate")
            let password = "StrongPass1!"
            _ = try await registerUser(app: app, email: email, password: password)
            
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(RegisterRequest(
                    firstName: "Test",
                    lastName: "User",
                    email: email,
                    password: password,
                    phone: "0601020304",
                    department: "IT",
                    position: "QA"
                ))
            }) { res async throws in
                XCTAssertEqual(res.status, .conflict)
            }
        }
    }
}

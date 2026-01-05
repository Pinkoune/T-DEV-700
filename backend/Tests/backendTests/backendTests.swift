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
    try await app.autoMigrate()
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

/// Helper pour créer un manager et obtenir son token
struct ManagerContext {
    let id: UUID
    let token: String
}

func createManagerWithToken(app: Application, prefix: String = "manager") async throws -> ManagerContext {
    let email = randomTestEmail(prefix: prefix)
    let password = "StrongPass1!"
    
    // Register
    var userID: UUID?
    try await app.test(.POST, "auth/register", beforeRequest: { req in
        try req.content.encode(RegisterRequest(
            firstName: "Manager",
            lastName: "Test",
            email: email,
            password: password,
            phone: "0600000000",
            department: "Management",
            position: "Manager"
        ))
    }) { res async throws in
        XCTAssertEqual(res.status, .ok)
        let response = try res.content.decode(LoginResponse.self)
        userID = UUID(uuidString: response.user.id!)
    }
    
    // Promote to manager
    let user = try await User.find(userID!, on: app.db)
    user?.role = "manager"
    try await user?.save(on: app.db)
    
    // Login to get token with manager role
    var token = ""
    try await app.test(.POST, "auth/login", beforeRequest: { req in
        try req.content.encode(LoginRequest(email: email, password: password))
    }) { res async throws in
        token = try res.content.decode(LoginResponse.self).token
    }
    
    return ManagerContext(id: userID!, token: token)
}

/// Helper pour créer une équipe
func createTeam(app: Application, manager: ManagerContext, name: String? = nil) async throws -> UUID {
    let teamName = name ?? "Team \(UUID().uuidString.prefix(8))"
    var teamID: UUID?
    
    try await app.test(.POST, "teams", beforeRequest: { req in
        req.headers.bearerAuthorization = .init(token: manager.token)
        try req.content.encode(CreateTeamRequest(
            name: teamName,
            description: "Test team",
            managerId: manager.id,
            color: "#007AFF"
        ))
    }) { res async throws in
        XCTAssertEqual(res.status, .ok)
        teamID = try res.content.decode(TeamResponse.self).id
    }
    
    return teamID!
}

/// Helper pour créer un employé
func createEmployee(app: Application, prefix: String = "employee") async throws -> (id: UUID, token: String) {
    let email = randomTestEmail(prefix: prefix)
    let password = "StrongPass1!"
    
    var userID: UUID?
    var token = ""
    
    try await app.test(.POST, "auth/register", beforeRequest: { req in
        try req.content.encode(RegisterRequest(
            firstName: "Employee",
            lastName: "Test",
            email: email,
            password: password,
            phone: "0600000000",
            department: "IT",
            position: "Developer"
        ))
    }) { res async throws in
        XCTAssertEqual(res.status, .ok)
    }
    
    try await app.test(.POST, "auth/login", beforeRequest: { req in
        try req.content.encode(LoginRequest(email: email, password: password))
    }) { res async throws in
        let response = try res.content.decode(LoginResponse.self)
        userID = UUID(uuidString: response.user.id!)
        token = response.token
    }
    
    return (userID!, token)
}

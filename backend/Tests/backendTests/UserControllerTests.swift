@testable import backend
import XCTVapor
import XCTest

final class UserControllerTests: XCTestCase {
    
    func testGetAllUsers() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let users = try res.content.decode([UserResponse].self)
                XCTAssertFalse(users.isEmpty)
            }
        }
    }
    
    func testGetAllUsersAsEmployeeFails() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app)
            
            try await app.test(.GET, "users", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async in
                XCTAssertTrue(res.status == .forbidden || res.status == .unauthorized)
            }
        }
    }
    
    func testCreateUser() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let newEmail = randomTestEmail(prefix: "newuser")
            
            try await app.test(.POST, "users", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
                try req.content.encode(CreateUserRequest(
                    firstName: "New",
                    lastName: "User",
                    email: newEmail,
                    phone: "0612345678",
                    role: "employee",
                    department: "IT",
                    position: "Developer",
                    weeklyHoursTarget: 35.0
                ))
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let user = try res.content.decode(UserResponse.self)
                XCTAssertEqual(user.email, newEmail.lowercased())
            }
        }
    }
    
    func testGetUser() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/\(manager.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let user = try res.content.decode(UserResponse.self)
                XCTAssertEqual(user.id, manager.id)
            }
        }
    }
    
    func testUpdateUser() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.PUT, "users/\(manager.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
                try req.content.encode(UpdateUserRequest(
                    firstName: "Updated",
                    lastName: nil,
                    email: nil,
                    phone: nil,
                    role: nil,
                    department: nil,
                    position: nil,
                    weeklyHoursTarget: nil,
                    isActive: nil
                ))
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let user = try res.content.decode(UserResponse.self)
                XCTAssertEqual(user.firstName, "Updated")
            }
        }
    }
    
    func testDeleteUser() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let employee = try await createEmployee(app: app)
            
            try await app.test(.DELETE, "users/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .noContent)
            }
            
            // Verify soft delete
            try await app.test(.GET, "users/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                let user = try res.content.decode(UserResponse.self)
                XCTAssertFalse(user.isActive)
            }
        }
    }
    
    func testGetUserProfile() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/\(manager.id)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let profile = try res.content.decode(UserProfileResponse.self)
                XCTAssertEqual(profile.user.id, manager.id)
                XCTAssertNotNil(profile.stats)
            }
        }
    }
    
    func testGetUserTeams() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/\(manager.id)/teams", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                _ = try res.content.decode([UserTeamResponse].self)
            }
        }
    }
    
    func testGetUserTimeEntries() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/\(manager.id)/timeentries", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                _ = try res.content.decode([TimeEntry].self)
            }
        }
    }
    
    func testGetUserPerformances() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/\(manager.id)/performances", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                _ = try res.content.decode([PerformanceResponse].self)
            }
        }
    }
    
    func testSearchUsers() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/search?q=Manager", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let users = try res.content.decode([UserResponse].self)
                XCTAssertTrue(users.contains(where: { $0.firstName.contains("Manager") || $0.lastName.contains("Manager") }))
            }
        }
    }
    
    func testGetUsersByRole() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/by-role/manager", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let users = try res.content.decode([UserResponse].self)
                XCTAssertTrue(users.allSatisfy { $0.role == "manager" })
            }
        }
    }
    
    func testGetActiveUsers() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/active", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let users = try res.content.decode([UserResponse].self)
                XCTAssertTrue(users.allSatisfy { $0.isActive })
            }
        }
    }
}

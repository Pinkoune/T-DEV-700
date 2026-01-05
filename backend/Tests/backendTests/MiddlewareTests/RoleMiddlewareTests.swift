@testable import backend
import XCTVapor
import XCTest

final class RoleMiddlewareTests: XCTestCase {
    
    func testManagerCanAccessManagerRoute() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .ok)
            }
        }
    }
    
    func testEmployeeCannotAccessManagerRoute() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "roletest")
            
            try await app.test(.GET, "users", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async in
                XCTAssertTrue(res.status == .forbidden || res.status == .unauthorized)
            }
        }
    }
    
    func testEmployeeCanAccessProtectedRoute() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "empaccess")
            
            try await app.test(.GET, "users/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async in
                XCTAssertEqual(res.status, .ok)
            }
        }
    }
    
    func testManagerCanAccessProtectedRoute() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "users/\(manager.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .ok)
            }
        }
    }
    
    func testManagerCanCreateTeam() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamName = "MiddlewareTest-\(UUID().uuidString.prefix(8))"
            
            try await app.test(.POST, "teams", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
                try req.content.encode([
                    "name": teamName,
                    "description": "Test team",
                    "managerId": manager.id.uuidString,
                    "color": "#FF0000"
                ])
            }) { res async in
                XCTAssertTrue(res.status == .created || res.status == .ok)
            }
        }
    }
    
    func testEmployeeCannotCreateTeam() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "empteam")
            
            try await app.test(.POST, "teams", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
                try req.content.encode([
                    "name": "Teamtest",
                    "description": "Test team",
                    "managerId": employee.id.uuidString,
                    "color": "#FFFFFFS"
                ])
            }) { res async in
                XCTAssertTrue(res.status == .forbidden || res.status == .unauthorized)
            }
        }
    }
    
    func testEmployeeCannotDeleteUser() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "empdel")
            let otherEmployee = try await createEmployee(app: app, prefix: "target")
            
            try await app.test(.DELETE, "users/\(otherEmployee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async in
                XCTAssertTrue(res.status == .forbidden || res.status == .unauthorized)
            }
        }
    }
    
    func testManagerCanDeleteUser() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let employee = try await createEmployee(app: app, prefix: "todelete")
            
            try await app.test(.DELETE, "users/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .noContent)
            }
        }
    }
}

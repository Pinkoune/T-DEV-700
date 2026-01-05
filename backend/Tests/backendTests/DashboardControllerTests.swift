@testable import backend
import XCTVapor
import XCTest

final class DashboardControllerTests: XCTestCase {
    
    func testGetUserDashboard() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "dashboard/user/\(manager.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let dashboard = try res.content.decode(UserDashboardResponse.self)
                XCTAssertEqual(dashboard.user.id, manager.id)
                XCTAssertNotNil(dashboard.stats)
            }
        }
    }
    
    func testGetUserDashboardAsEmployee() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app)
            
            try await app.test(.GET, "dashboard/user/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let dashboard = try res.content.decode(UserDashboardResponse.self)
                XCTAssertEqual(dashboard.user.id, employee.id)
            }
        }
    }
    
    func testGetUserDashboardWithoutAuth() async throws {
        try await withTestApp { app in
            let fakeUserID = UUID()
            
            try await app.test(.GET, "dashboard/user/\(fakeUserID)") { res async in
                XCTAssertEqual(res.status, .unauthorized)
            }
        }
    }
    
    func testGetTeamHoursStats() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            
            try await app.test(.GET, "dashboard/team/\(teamID)/hours", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let stats = try res.content.decode(TeamHoursStatsResponse.self)
                XCTAssertEqual(stats.teamId, teamID)
                XCTAssertEqual(stats.period, "month")
            }
        }
    }
    
    func testGetTeamHoursStatsWeekPeriod() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            
            try await app.test(.GET, "dashboard/team/\(teamID)/hours?period=week", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let stats = try res.content.decode(TeamHoursStatsResponse.self)
                XCTAssertEqual(stats.period, "week")
            }
        }
    }
    
    func testGetTeamHoursStatsAsEmployeeFails() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            let employee = try await createEmployee(app: app)
            
            try await app.test(.GET, "dashboard/team/\(teamID)/hours", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async in
                XCTAssertTrue(res.status == .forbidden || res.status == .unauthorized)
            }
        }
    }
    
    func testGetEmployeeHoursStats() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let employee = try await createEmployee(app: app)
            
            try await app.test(.GET, "dashboard/employee/\(employee.id)/hours", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let stats = try res.content.decode(EmployeeHoursStatsResponse.self)
                XCTAssertEqual(stats.userId, employee.id)
                XCTAssertNotNil(stats.summary)
            }
        }
    }
    
    func testGetEmployeeHoursStatsWeekPeriod() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let employee = try await createEmployee(app: app)
            
            try await app.test(.GET, "dashboard/employee/\(employee.id)/hours?period=week", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let stats = try res.content.decode(EmployeeHoursStatsResponse.self)
                XCTAssertEqual(stats.period, "week")
            }
        }
    }
    
    func testGetEmployeeHoursStatsAsEmployeeFails() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app)
            
            try await app.test(.GET, "dashboard/employee/\(employee.id)/hours", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
            }) { res async in
                XCTAssertTrue(res.status == .forbidden || res.status == .unauthorized)
            }
        }
    }
}

@testable import backend
import XCTVapor
import XCTest

final class TeamControllerTests: XCTestCase {
    
    
    func testCreateTeam() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager, name: "New Team \(UUID().uuidString.prefix(8))")
            XCTAssertNotNil(teamID)
        }
    }
    
    func testCreateTeamAsEmployeeFails() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app)
            
            try await app.test(.POST, "teams", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: employee.token)
                try req.content.encode(CreateTeamRequest(
                    name: "Unauthorized Team",
                    description: "Should fail",
                    managerId: employee.id,
                    color: "#00FF00"
                ))
            }) { res async in
                XCTAssertTrue(res.status == .forbidden || res.status == .unauthorized)
            }
        }
    }
    
    func testGetAllTeams() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            
            try await app.test(.GET, "teams", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .ok)
            }
        }
    }
    
    func testGetTeamDetails() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            
            try await app.test(.GET, "teams/\(teamID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let detail = try res.content.decode(TeamDetailResponse.self)
                XCTAssertEqual(detail.team.id, teamID)
            }
        }
    }
    
    func testUpdateTeam() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            
            let newName = "Updated Name \(UUID().uuidString.prefix(8))"
            try await app.test(.PUT, "teams/\(teamID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
                try req.content.encode(UpdateTeamRequest(name: newName, description: nil, managerId: nil, color: nil, isActive: nil))
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let updated = try res.content.decode(TeamResponse.self)
                XCTAssertEqual(updated.name, newName)
            }
        }
    }
    
    func testDeleteTeam() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            
            try await app.test(.DELETE, "teams/\(teamID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .noContent)
            }
            
            // Verify soft delete
            try await app.test(.GET, "teams/\(teamID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                let detail = try res.content.decode(TeamDetailResponse.self)
                XCTAssertFalse(detail.team.isActive)
            }
        }
    }
    
    
    func testAddMember() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            let employee = try await createEmployee(app: app)
            
            try await app.test(.POST, "teams/\(teamID)/members/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .created)
            }
            
            // Verify member added
            try await app.test(.GET, "teams/\(teamID)/members", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                let members = try res.content.decode([UserResponse].self)
                XCTAssertTrue(members.contains(where: { $0.id == employee.id }))
            }
        }
    }
    
    func testRemoveMember() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            let employee = try await createEmployee(app: app)
            
            // Add then remove
            try await app.test(.POST, "teams/\(teamID)/members/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .created)
            }
            
            try await app.test(.DELETE, "teams/\(teamID)/members/\(employee.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async in
                XCTAssertEqual(res.status, .noContent)
            }
            
            try await app.test(.GET, "teams/\(teamID)/members", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                let members = try res.content.decode([UserResponse].self)
                XCTAssertFalse(members.contains(where: { $0.id == employee.id }))
            }
        }
    }
    
    
    func testSearchTeams() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let uniqueName = "Searchable\(UUID().uuidString.prefix(8))"
            _ = try await createTeam(app: app, manager: manager, name: uniqueName)
            
            try await app.test(.GET, "teams/search?q=Searchable", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let teams = try res.content.decode([TeamResponse].self)
                XCTAssertTrue(teams.contains(where: { $0.name.contains("Searchable") }))
            }
        }
    }
    
    func testGetActiveTeams() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            
            try await app.test(.GET, "teams/active", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let teams = try res.content.decode([TeamResponse].self)
                XCTAssertTrue(teams.allSatisfy { $0.isActive })
                XCTAssertTrue(teams.contains(where: { $0.id == teamID }))
            }
        }
    }
    
    func testGetTeamsByManager() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            _ = try await createTeam(app: app, manager: manager)
            
            try await app.test(.GET, "teams/by-manager/\(manager.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let teams = try res.content.decode([TeamResponse].self)
                XCTAssertTrue(teams.allSatisfy { $0.managerId == manager.id })
            }
        }
    }
    
    
    func testGetTeamStats() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            
            try await app.test(.GET, "teams/\(teamID)/stats", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let stats = try res.content.decode(TeamStatsResponse.self)
                XCTAssertEqual(stats.teamId, teamID.uuidString)
            }
        }
    }
    
    func testGetTeamPerformance() async throws {
        try await withTestApp { app in
            let manager = try await createManagerWithToken(app: app)
            let teamID = try await createTeam(app: app, manager: manager)
            
            try await app.test(.GET, "teams/\(teamID)/performance", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: manager.token)
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let performances = try res.content.decode([TeamMemberPerformance].self)
                XCTAssertNotNil(performances)
            }
        }
    }
}

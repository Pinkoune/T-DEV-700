@testable import backend
import XCTVapor
import XCTest

final class PerformanceControllerTests: XCTestCase {
    
    func testGetAllPerformances() async throws {
        try await withTestApp { app in
            try await app.test(.GET, "performances") { res async throws in
                XCTAssertEqual(res.status, .ok)
                _ = try res.content.decode([PerformanceResponse].self)
            }
        }
    }
    
    func testCreatePerformance() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "perf")
            
            try await app.test(.POST, "performances", beforeRequest: { req in
                try req.content.encode(CreatePerformanceRequest(
                    userId: employee.id,
                    period: "month",
                    index: 85.0
                ))
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let perf = try res.content.decode(PerformanceResponse.self)
                XCTAssertEqual(perf.userId, employee.id)
                XCTAssertEqual(perf.period, "month")
                XCTAssertEqual(perf.index, 85.0)
            }
        }
    }
    
    func testGetPerformance() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "perfget")
            
            // Create performance first
            var perfID: UUID?
            try await app.test(.POST, "performances", beforeRequest: { req in
                try req.content.encode(CreatePerformanceRequest(
                    userId: employee.id,
                    period: "week",
                    index: 75.0
                ))
            }) { res async throws in
                perfID = try res.content.decode(PerformanceResponse.self).id
            }
            
            // Get it
            try await app.test(.GET, "performances/\(perfID!)") { res async throws in
                XCTAssertEqual(res.status, .ok)
                let perf = try res.content.decode(PerformanceResponse.self)
                XCTAssertEqual(perf.id, perfID)
            }
        }
    }
    
    func testUpdatePerformance() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "perfupd")
            
            // Create performance
            var perfID: UUID?
            try await app.test(.POST, "performances", beforeRequest: { req in
                try req.content.encode(CreatePerformanceRequest(
                    userId: employee.id,
                    period: "day",
                    index: 60.0
                ))
            }) { res async throws in
                perfID = try res.content.decode(PerformanceResponse.self).id
            }
            
            // Update it
            try await app.test(.PUT, "performances/\(perfID!)", beforeRequest: { req in
                try req.content.encode(UpdatePerformanceRequest(
                    period: nil,
                    index: 90.0
                ))
            }) { res async throws in
                XCTAssertEqual(res.status, .ok)
                let perf = try res.content.decode(PerformanceResponse.self)
                XCTAssertEqual(perf.index, 90.0)
            }
        }
    }
    
    func testDeletePerformance() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "perfdel")
            
            // Create performance
            var perfID: UUID?
            try await app.test(.POST, "performances", beforeRequest: { req in
                try req.content.encode(CreatePerformanceRequest(
                    userId: employee.id,
                    period: "month",
                    index: 50.0
                ))
            }) { res async throws in
                perfID = try res.content.decode(PerformanceResponse.self).id
            }
            
            // Delete it
            try await app.test(.DELETE, "performances/\(perfID!)") { res async in
                XCTAssertEqual(res.status, .noContent)
            }
            
            // Verify deleted
            try await app.test(.GET, "performances/\(perfID!)") { res async in
                XCTAssertEqual(res.status, .notFound)
            }
        }
    }
    
    func testGetPerformancesByUser() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "perfbyuser")
            
            // Create a performance
            try await app.test(.POST, "performances", beforeRequest: { req in
                try req.content.encode(CreatePerformanceRequest(
                    userId: employee.id,
                    period: "week",
                    index: 80.0
                ))
            }) { res async in
                XCTAssertEqual(res.status, .ok)
            }
            
            // Get by user
            try await app.test(.GET, "performances/by-user/\(employee.id)") { res async throws in
                XCTAssertEqual(res.status, .ok)
                let perfs = try res.content.decode([PerformanceResponse].self)
                XCTAssertTrue(perfs.allSatisfy { $0.userId == employee.id })
            }
        }
    }
    
    func testGetLatestPerformance() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "perflatest")
            
            // Create performance
            try await app.test(.POST, "performances", beforeRequest: { req in
                try req.content.encode(CreatePerformanceRequest(
                    userId: employee.id,
                    period: "month",
                    index: 95.0
                ))
            }) { res async in
                XCTAssertEqual(res.status, .ok)
            }
            
            // Get latest
            try await app.test(.GET, "performances/latest/\(employee.id)") { res async throws in
                XCTAssertEqual(res.status, .ok)
                let perf = try res.content.decode(PerformanceResponse.self)
                XCTAssertEqual(perf.userId, employee.id)
            }
        }
    }
    
    func testGetLatestPerformanceNotFound() async throws {
        try await withTestApp { app in
            let employee = try await createEmployee(app: app, prefix: "perfnone")
            
            try await app.test(.GET, "performances/latest/\(employee.id)") { res async in
                XCTAssertEqual(res.status, .notFound)
            }
        }
    }
}

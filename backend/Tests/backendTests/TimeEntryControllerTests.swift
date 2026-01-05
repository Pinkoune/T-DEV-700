@testable import backend
import XCTVapor
import XCTest

final class TimeEntryControllerTests: XCTestCase {
    func testClockInCreatesActiveEntry() async throws {
        try await withTestApp { app in
            let (userID, token) = try await createUserWithToken(app: app, prefix: "clockin")
            let entry = try await clockIn(app: app, token: token, userID: userID)
            
            XCTAssertEqual(entry.userId, userID)
            XCTAssertEqual(entry.status, "active")
            XCTAssertNil(entry.departure)
        }
    }
    
    func testClockOutCompletesEntry() async throws {
        try await withTestApp { app in
            let (userID, token) = try await createUserWithToken(app: app, prefix: "clockout")
            let activeEntry = try await clockIn(app: app, token: token, userID: userID)
            
            let completedEntry = try await clockOut(app: app, token: token, entryID: activeEntry.id!)
            XCTAssertEqual(completedEntry.status, "completed")
            XCTAssertNotNil(completedEntry.departure)
            XCTAssertNotNil(completedEntry.hoursWorked)
        }
    }
    
    func testActiveEntryEndpointReflectsState() async throws {
        try await withTestApp { app in
            let (userID, token) = try await createUserWithToken(app: app, prefix: "active")
            let activeEntry = try await clockIn(app: app, token: token, userID: userID)
            
            var response = try await fetchActiveEntry(app: app, token: token, userID: userID)
            XCTAssertTrue(response.hasActiveEntry)
            XCTAssertEqual(response.timeEntry?.id, activeEntry.id)
            
            _ = try await clockOut(app: app, token: token, entryID: activeEntry.id!)
            response = try await fetchActiveEntry(app: app, token: token, userID: userID)
            XCTAssertFalse(response.hasActiveEntry)
            XCTAssertNil(response.timeEntry)
        }
    }
}


private func createUserWithToken(app: Application, prefix: String) async throws -> (UUID, String) {
    let registerResponse = try await registerUser(app: app, email: randomTestEmail(prefix: prefix), password: "StrongPass1!")
    guard let idString = registerResponse.user.id, let userID = UUID(uuidString: idString) else {
        XCTFail("User ID missing after registration")
        throw Abort(.internalServerError)
    }
    return (userID, registerResponse.token)
}

private func clockIn(app: Application, token: String, userID: UUID) async throws -> TimeEntryResponse {
    var responseBody: TimeEntryResponse?
    try await app.test(.POST, "timeentries/clock-in", beforeRequest: { req in
        req.headers.bearerAuthorization = .init(token: token)
        try req.content.encode(ClockInRequest(userId: userID, notes: "Test"))
    }) { res async throws in
        XCTAssertEqual(res.status, .ok)
        responseBody = try res.content.decode(TimeEntryResponse.self)
    }
    return responseBody!
}

private func clockOut(app: Application, token: String, entryID: UUID) async throws -> TimeEntryResponse {
    var responseBody: TimeEntryResponse?
    try await app.test(.POST, "timeentries/clock-out/\(entryID.uuidString)", beforeRequest: { req in
        req.headers.bearerAuthorization = .init(token: token)
    }) { res async throws in
        XCTAssertEqual(res.status, .ok)
        responseBody = try res.content.decode(TimeEntryResponse.self)
    }
    return responseBody!
}

private func fetchActiveEntry(app: Application, token: String, userID: UUID) async throws -> ActiveTimeEntryResponse {
    var responseBody: ActiveTimeEntryResponse?
    try await app.test(.GET, "timeentries/active/\(userID.uuidString)", beforeRequest: { req in
        req.headers.bearerAuthorization = .init(token: token)
    }) { res async throws in
        XCTAssertEqual(res.status, .ok)
        responseBody = try res.content.decode(ActiveTimeEntryResponse.self)
    }
    return responseBody!
}

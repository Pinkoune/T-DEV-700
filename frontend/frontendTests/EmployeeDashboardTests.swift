//
//  EmployeeDashboardTests.swift
//  frontendTests
//
//  Created by Jérémy Barcelo on 17/10/2025.
//

import Testing
@testable import frontend

@Suite("EmployeeDashboard Tests")
struct EmployeeDashboardSimpleTests {
    
    @Test("Dashboard sample activities count")
    func testSampleActivitiesCount() {
        let dashboard = EmployeeDashboard()
        let activities = dashboard.sampleActivities
        
        #expect(activities.count == 4)
    }
    
    @Test("First activity is today and active")
    func testTodayActivity() {
        let dashboard = EmployeeDashboard()
        let activities = dashboard.sampleActivities
        
        let first = activities[0]
        #expect(first.title == "Aujourd'hui")
        #expect(first.isActive == true)
    }
}

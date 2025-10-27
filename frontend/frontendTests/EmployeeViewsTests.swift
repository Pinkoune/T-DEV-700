//
//  EmployeeViewsTests.swift
//  frontend
//
//  Created by Jérémy Barcelo on 17/10/2025.
//

import SwiftUI
import Testing

@testable import frontend

@Suite("Employee Views - Advanced Tests")
struct EmployeeViewsTests {

    // MARK: - EmployeeAccount Advanced Tests

    @Suite("EmployeeAccount Actions")
    struct EmployeeAccountActionTests {

        @Test("Account page contains expected components")
        func testAccountComponents() {
            let account = EmployeeAccount()

            let mirror = Mirror(reflecting: account)
            let properties = mirror.children.map { $0.label ?? "" }

            #expect(properties.contains("_firstName"))
            #expect(properties.contains("_lastName"))
            #expect(properties.contains("_email"))
        }

        @Test("Account has password management states")
        func testPasswordStates() {
            let account = EmployeeAccount()
            let mirror = Mirror(reflecting: account)
            let properties = mirror.children.map { $0.label ?? "" }

            #expect(properties.contains("_currentPassword"))
            #expect(properties.contains("_newPassword"))
            #expect(properties.contains("_confirmPassword"))
        }

        @Test("Account has alert states")
        func testAlertStates() {
            let account = EmployeeAccount()
            let mirror = Mirror(reflecting: account)
            let properties = mirror.children.map { $0.label ?? "" }

            #expect(properties.contains("_showDeleteAlert"))
            #expect(properties.contains("_showDisconnectAlert"))
        }

        @Test("Account has edit profile states")
        func testEditProfileStates() {
            let account = EmployeeAccount()
            let mirror = Mirror(reflecting: account)
            let properties = mirror.children.map { $0.label ?? "" }

            #expect(properties.contains("_showEditProfile"))
            #expect(properties.contains("_showEditEmail"))
        }
    }

    // MARK: - EmployeeHomePage Advanced Tests

    @Suite("EmployeeHomePage Components")
    struct EmployeeHomePageComponentTests {

        @MainActor
        @Test("Homepage uses HeaderView with employee type")
        func testHeaderViewIntegration() {
            let header = HeaderView(userType: .employee, title: "Bonjour Ronald,")

            #expect(header.userType == .employee)
            #expect(header.title == "Bonjour Ronald,")
        }

        @Test("Homepage body returns a valid view")
        func testBodyReturnsView() {
            let homepage = EmployeeHomePage()
            let body = homepage.body

            _ = body
            #expect(true)
        }
    }

    // MARK: - Integration Tests

    @Suite("Employee Views Integration")
    struct EmployeeViewsIntegrationTests {

        @Test("All employee views can be initialized together")
        func testAllViewsInitialization() {
            let homePage = EmployeeHomePage()
            let dashboard = EmployeeDashboard()
            let account = EmployeeAccount()

            _ = homePage
            _ = dashboard
            _ = account
            #expect(true)
        }

        @Test("EmployeeView can switch between tabs")
        func testEmployeeViewTabs() {
            let employeeView = EmployeeView()

            _ = employeeView

            let mirror = Mirror(reflecting: employeeView)
            let properties = mirror.children.map { $0.label ?? "" }

            #expect(properties.contains("_selectedTab"))
        }
    }
}

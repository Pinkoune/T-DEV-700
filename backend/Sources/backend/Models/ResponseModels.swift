import Vapor
import Foundation

// Requêtes pour les Models

struct CreateUserRequest: Content, Validatable {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let role: String?
    let department: String?
    let position: String?
    let weeklyHoursTarget: Double?
    
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty && .count(2...50))
        validations.add("lastName", as: String.self, is: !.empty && .count(2...50))
        validations.add("email", as: String.self, is: .email)
        validations.add("phone", as: String.self, is: .count(10...15))
    }
}

struct UpdateUserRequest: Content {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let role: String?
    let department: String?
    let position: String?
    let weeklyHoursTarget: Double?
    let isActive: Bool?
}

struct CreateTimeEntryRequest: Content, Validatable {
    let userId: String
    let notes: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: String.self, is: !.empty)
    }
}

struct UpdateTimeEntryRequest: Content {
    let arrival: Date?
    let departure: Date?
    let notes: String?
    let status: String?
}

struct ClockInRequest: Content, Validatable {
    let userId: String
    let notes: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: String.self, is: !.empty)
    }
}

// Réponse pour les Models

struct UserResponse: Content {
    let id: String?
    let firstName: String
    let lastName: String
    let fullName: String
    let initials: String
    let email: String
    let phone: String
    let role: String
    let displayRole: String
    let department: String?
    let position: String?
    let hireDate: Date?
    let isActive: Bool
    let weeklyHoursTarget: Double
    let yearsOfService: Int?
    let isManager: Bool
    let isAdmin: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(from user: User) {
        self.id = user.id
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.fullName = user.fullName
        self.initials = user.initials
        self.email = user.email
        self.phone = user.phone
        self.role = user.role
        self.displayRole = user.displayRole
        self.department = user.department
        self.position = user.position
        self.hireDate = user.hireDate
        self.isActive = user.isActive
        self.weeklyHoursTarget = user.weeklyHoursTarget
        self.yearsOfService = user.yearsOfService
        self.isManager = user.isManager
        self.isAdmin = user.isAdmin
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }
}

struct TimeEntryResponse: Content {
    let id: String?
    let userId: String
    let arrival: Date
    let departure: Date?
    let workDuration: String
    let calculatedHours: Double
    let isCurrentlyWorking: Bool
    let isOvertime: Bool
    let overtimeHours: Double
    let status: String
    let notes: String?
    let workPeriod: String
    
    init(from timeEntry: TimeEntry) {
        self.id = timeEntry.id
        self.userId = timeEntry.userId
        self.arrival = timeEntry.arrival
        self.departure = timeEntry.departure
        self.workDuration = timeEntry.workDuration
        self.calculatedHours = timeEntry.calculatedHours
        self.isCurrentlyWorking = timeEntry.isCurrentlyWorking
        self.isOvertime = timeEntry.isOvertime
        self.overtimeHours = timeEntry.overtimeHours
        self.status = timeEntry.status
        self.notes = timeEntry.notes
        self.workPeriod = timeEntry.workPeriod
    }
}

struct ActiveTimeEntryResponse: Content {
    let hasActiveEntry: Bool
    let timeEntry: TimeEntryResponse?
}

import Vapor
import Fluent
import Foundation

final class User: Model, Content, Authenticatable, @unchecked Sendable {
	static let schema = "users"
	
	@ID(key: .id)
	var id: UUID?
	
	@Field(key: "first_name")
	var firstName: String
	
	@Field(key: "last_name")
	var lastName: String
	
	@Field(key: "email")
	var email: String
	
	@Field(key: "password_hash")
	var passwordHash: String
	
	@Field(key: "phone")
	var phone: String
	
	@Field(key: "role")
	var role: String 
	
	@OptionalField(key: "department")
	var department: String?
	
	@OptionalField(key: "position")
	var position: String?
	
	@OptionalField(key: "hire_date")
	var hireDate: Date?
	
	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?
	
	@Field(key: "is_active")
	var isActive: Bool
	
	@Field(key: "weekly_hours_target")
	var weeklyHoursTarget: Double 
	
	@Children(for: \.$user)
	var timeEntries: [TimeEntry]
	
	@Children(for: \.$user)
	var performances: [Performance]
	
	var fullName: String {
		return "\(firstName) \(lastName)"
	}
	
	var initials: String {
		let firstInitial = firstName.first?.uppercased() ?? ""
		let lastInitial = lastName.first?.uppercased() ?? ""
		return "\(firstInitial)\(lastInitial)"
	}
	
	var isManager: Bool {
		return role == "manager"
	}
	
	
	var yearsOfService: Int? {
		guard let hireDate = hireDate else { return nil }
		return Calendar.current.dateComponents([.year], from: hireDate, to: Date()).year
	}
	
	var displayRole: String {
		switch role {
		case "manager":
			return "Manager"
		case "employee":
			return "Employé"
		default:
			return "Utilisateur"
		}
	}
	
	
	
	init() {}
	
	init(id: UUID? = nil, firstName: String, lastName: String, email: String, passwordHash: String, phone: String, role: String = "employee", department: String? = nil, position: String? = nil, weeklyHoursTarget: Double = 35.0) {
		self.id = id
		self.firstName = firstName
		self.lastName = lastName
		self.email = email
		self.passwordHash = passwordHash
		self.phone = phone
		self.role = role
		self.department = department
		self.position = position
		self.hireDate = Date()
		self.isActive = true
		self.weeklyHoursTarget = weeklyHoursTarget
	}
}

extension User: Validatable {
	static func validations(_ validations: inout Validations) {
		validations.add("firstName", as: String.self, is: !.empty && .count(2...50))
		validations.add("lastName", as: String.self, is: !.empty && .count(2...50))
		validations.add("email", as: String.self, is: .email)
		validations.add("phone", as: String.self, is: .count(10...15))
		validations.add("role", as: String.self, is: .in("manager", "employee"))
		validations.add("weeklyHoursTarget", as: Double.self, is: .range(1...80))
	}
}

struct UserDTO: Content {
	let id: UUID
	let firstName: String
	let lastName: String
	let email: String
	let phone: String
	let role: String
	let department: String?
	let position: String?
	let hireDate: Date?
	let isActive: Bool
	let weeklyHoursTarget: Double
	let fullName: String
	let displayRole: String
	
	init(from user: User) throws {
		guard let id = user.id else {
			throw Abort(.internalServerError, reason: "User ID is missing")
		}
		self.id = id
		self.firstName = user.firstName
		self.lastName = user.lastName
		self.email = user.email
		self.phone = user.phone
		self.role = user.role
		self.department = user.department
		self.position = user.position
		self.hireDate = user.hireDate
		self.isActive = user.isActive
		self.weeklyHoursTarget = user.weeklyHoursTarget
		self.fullName = user.fullName
		self.displayRole = user.displayRole
	}
}

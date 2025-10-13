import Vapor
import FirebaseFirestore
import Foundation

struct User: Codable, Validatable {
	var id: String?
	var firstName: String
	var lastName: String
	var email: String
	var passwordHash: String 
	var phone: String
	var role: String // "admin", "manager", "employee"
	var department: String?
	var position: String?
	var hireDate: Date?
	var createdAt: Date
	var updatedAt: Date
	var isActive: Bool
	var weeklyHoursTarget: Double // Objectif d'heures par semaine
	
	// Propriétés calculées
	var fullName: String {
		return "\(firstName) \(lastName)"
	}
	
	var initials: String {
		let firstInitial = firstName.first?.uppercased() ?? ""
		let lastInitial = lastName.first?.uppercased() ?? ""
		return "\(firstInitial)\(lastInitial)"
	}
	
	var isManager: Bool {
		return role == "manager" || role == "admin"
	}
	
	var isAdmin: Bool {
		return role == "admin"
	}
	
	var yearsOfService: Int? {
		guard let hireDate = hireDate else { return nil }
		return Calendar.current.dateComponents([.year], from: hireDate, to: Date()).year
	}
	
	var displayRole: String {
		switch role {
		case "admin":
			return "Administrateur"
		case "manager":
			return "Manager"
		case "employee":
			return "Employé"
		default:
			return "Utilisateur"
		}
	}
	
	// Validation
	static func validations(_ validations: inout Validations) {
		validations.add("firstName", as: String.self, is: !.empty && .count(2...50))
		validations.add("lastName", as: String.self, is: !.empty && .count(2...50))
		validations.add("email", as: String.self, is: .email)
		validations.add("phone", as: String.self, is: .count(10...15) && .characterSet(.decimalDigits.union(.init(charactersIn: "+- ()"))))
		validations.add("role", as: String.self, is: .in("admin", "manager", "employee"))
		validations.add("weeklyHoursTarget", as: Double.self, is: .range(1...80))
	}
	
	// Initializer
	init(firstName: String, lastName: String, email: String, passwordHash: String, phone: String, role: String = "employee", department: String? = nil, position: String? = nil, weeklyHoursTarget: Double = 35.0) {
		self.id = nil
		self.firstName = firstName
		self.lastName = lastName
		self.email = email
		self.passwordHash = passwordHash
		self.phone = phone
		self.role = role
		self.department = department
		self.position = position
		self.hireDate = Date()
		self.createdAt = Date()
		self.updatedAt = Date()
		self.isActive = true
		self.weeklyHoursTarget = weeklyHoursTarget
	}
}

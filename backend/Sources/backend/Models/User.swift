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
		validations.add("email", as: String.self, is: .email && .valid(EmailDomainValidator()))
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

// Fonction qui contient un tableau des domaines bloqués	

struct EmailDomainValidator: Validator {
	private let blockedDomains = [
		"mailpit.local",
		"mailtrap.io",
		"ethereal.email",
		"temp-mail.org",
		"guerrillamail.com",
		"10minutemail.com",
		"throwaway.email",
		"tempmail.com",
		"yopmail.com",
		"mailinator.com",
		"trashmail.com",
		"fakeinbox.com",
		"dispostable.com",
		"getnada.com",
		"sharklasers.com",
		"guerrillamailblock.com",
		"spam4.me",
		"grr.la",
		"example.com",
		"test.com",
	]
	
	private let suspiciousPatterns = [
		"temp",
		"fake",
		"trash",
		"spam",
		"disposable",
		"throwaway",
		"test123"
	]
	
	var validatorReadable: String {
		"un domaine d'email valide (les emails temporaires ne sont pas autorisés)"
	}
	
	func validate(_ value: String) -> ValidatorResult {
		let lowercasedEmail = value.lowercased()
		
		guard let domain = extractDomain(from: lowercasedEmail) else {
			return .invalid(reason: "Format d'email invalide")
		}
		
		if blockedDomains.contains(where: { domain.contains($0) }) {
			return .invalid(reason: "Ce domaine d'email n'est pas autorisé. Veuillez utiliser une adresse email professionnelle ou personnelle valide.")
		}
		
		if suspiciousPatterns.contains(where: { lowercasedEmail.contains($0) }) {
			return .invalid(reason: "Cette adresse email semble suspecte. Veuillez utiliser une adresse email valide.")
		}
		
		return .valid
	}
	
	private func extractDomain(from email: String) -> String? {
		let components = email.split(separator: "@")
		guard components.count == 2 else { return nil }
		return String(components[1])
	}
}

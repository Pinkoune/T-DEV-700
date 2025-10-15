import Vapor
import FirebaseFirestore
import Foundation

struct Team: Codable, Validatable {
	var id: String?
	var name: String
	var description: String
	var members: [String] // IDs users
	var managerId: String
	var color: String // Codes couleur hex "#FF0000"
	var createdAt: Date
	var updatedAt: Date
	var isActive: Bool
	
	// Propriétés calculées
	var memberCount: Int {
		return members.count
	}
	
	var isLargeTeam: Bool {
		return members.count > 10
	}
	
	var teamSize: String {
		switch members.count {
		case 1:
			return "Solo"
		case 2...5:
			return "Petite équipe"
		case 6...15:
			return "Équipe moyenne"
		default:
			return "Grande équipe"
		}
	}
	
	func isMember(_ userId: String) -> Bool {
		return members.contains(userId)
	}
	
	func isManager(_ userId: String) -> Bool {
		return managerId == userId
	}
	
	// Validation
	static func validations(_ validations: inout Validations) {
		validations.add("name", as: String.self, is: !.empty && .count(2...50))
		validations.add("description", as: String.self, is: .count(...500))
		validations.add("managerId", as: String.self, is: !.empty)
		validations.add("color", as: String.self, is: .characterSet(.alphanumerics.union(.init(charactersIn: "#"))) && .count(7...7))
	}
	
	// Initializer avec valeurs par défaut
	init(name: String, description: String, managerId: String, color: String = "#007AFF") {
		self.id = nil
		self.name = name
		self.description = description
		self.members = [managerId] // Le manager est automatiquement membre
		self.managerId = managerId
		self.color = color
		self.createdAt = Date()
		self.updatedAt = Date()
		self.isActive = true
	}
}

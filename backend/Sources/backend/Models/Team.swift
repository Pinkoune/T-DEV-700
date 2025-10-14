import Vapor
import Fluent
import Foundation

final class Team: Model, Content, @unchecked Sendable {
	static let schema = "teams"
	
	@ID(key: .id)
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Field(key: "description")
	var description: String
	
	@Field(key: "members")
	var members: [UUID] // IDs users
	
	@Field(key: "manager_id")
	var managerId: UUID
	
	@Field(key: "color")
	var color: String // Codes couleur hex "#FF0000"
	
	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?
	
	@Field(key: "is_active")
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
	
	func isMember(_ userId: UUID) -> Bool {
		return members.contains(userId)
	}
	
	func isManager(_ userId: UUID) -> Bool {
		return managerId == userId
	}
	
	// Initializer
	init() {}
	
	init(id: UUID? = nil, name: String, description: String, managerId: UUID, color: String = "#007AFF") {
		self.id = id
		self.name = name
		self.description = description
		self.members = [managerId] // Le manager est automatiquement membre
		self.managerId = managerId
		self.color = color
		self.isActive = true
	}
}

// MARK: - Validations
extension Team: Validatable {
	static func validations(_ validations: inout Validations) {
		validations.add("name", as: String.self, is: !.empty && .count(2...50))
		validations.add("description", as: String.self, is: .count(...500))
		validations.add("color", as: String.self, is: .count(7...7))
	}
}

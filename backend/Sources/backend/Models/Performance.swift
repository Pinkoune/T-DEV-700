import Vapor
import Fluent
import Foundation

final class Performance: Model, Content, @unchecked Sendable {
	static let schema = "performances"
	
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "user_id")
	var user: User
	
	@Field(key: "period")
	var period: String // "day", "week", "month"
	
	@Field(key: "index")
	var index: Double // Basé sur des heures/objectifs
	
	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?
	
	// Propriétés calculées
	var performanceLevel: String {
		switch index {
		case 90...100:
			return "Excellent"
		case 75..<90:
			return "Très bien"
		case 60..<75:
			return "Bien"
		case 40..<60:
			return "Moyen"
		default:
			return "À améliorer"
		}
	}
	
	var isExcellent: Bool {
		return index >= 90
	}
	
	// Initializer
	init() {}
	
	init(id: UUID? = nil, userId: UUID, period: String, index: Double) {
		self.id = id
		self.$user.id = userId
		self.period = period
		self.index = index
	}
}

// MARK: - Validations
extension Performance: Validatable {
	static func validations(_ validations: inout Validations) {
		validations.add("period", as: String.self, is: .in("day", "week", "month"))
		validations.add("index", as: Double.self, is: .range(0...100))
	}
}

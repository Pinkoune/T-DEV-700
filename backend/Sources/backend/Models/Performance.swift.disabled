import Vapor
import FirebaseFirestore
import Foundation

struct Performance: Codable, Validatable {
	var id: String?
	var userId: String
	var period: String // "jour", "semaine", "mois"
	var index: Double // Basé sur des heures/objectifs
	var createdAt: Date
	var updatedAt: Date
	
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
	
	// Validation
	static func validations(_ validations: inout Validations) {
		validations.add("userId", as: String.self, is: !.empty)
		validations.add("period", as: String.self, is: .in("day", "week", "month"))
		validations.add("index", as: Double.self, is: .range(0...100))
	}
	
	// Initializer avec timestamps automatiques
	init(userId: String, period: String, index: Double) {
		self.id = nil
		self.userId = userId
		self.period = period
		self.index = index
		self.createdAt = Date()
		self.updatedAt = Date()
	}
}

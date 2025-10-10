import Vapor
import Foundation

struct TimeEntry: Codable, Validatable {
	var id: String?
	var userId: String
	var arrival: Date
	var departure: Date?
	var hoursWorked: Double? // Calculé automatiquement
	var status: String // "active", "completed", "cancelled"
	var notes: String? // Notes optionnelles
	var createdAt: Date
	var updatedAt: Date
	
	// Propriétés calculées
	var calculatedHours: Double {
		guard let departure = departure else {
			// Si pas encore parti, calculer depuis l'arrivée jusqu'à maintenant
			return Date().timeIntervalSince(arrival) / 3600
		}
		return departure.timeIntervalSince(arrival) / 3600
	}
	
	var isCurrentlyWorking: Bool {
		return departure == nil && status == "active"
	}
	
	var workDuration: String {
		let hours = calculatedHours
		let h = Int(hours)
		let m = Int((hours - Double(h)) * 60)
		return String(format: "%dh%02dm", h, m)
	}
	
	var isOvertime: Bool {
		return calculatedHours > 8.0
	}
	
	var overtimeHours: Double {
		return max(0, calculatedHours - 8.0)
	}
	
	var workPeriod: String {
		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm"
		let arrivalTime = formatter.string(from: arrival)
		
		if let departure = departure {
			let departureTime = formatter.string(from: departure)
			return "\(arrivalTime) - \(departureTime)"
		} else {
			return "\(arrivalTime) - En cours"
		}
	}
	
	// Validation
	static func validations(_ validations: inout Validations) {
		validations.add("userId", as: String.self, is: !.empty)
		validations.add("status", as: String.self, is: .in("active", "completed", "cancelled"))
	}
	
	// Méthodes utilitaires
	mutating func clockOut() {
		self.departure = Date()
		self.hoursWorked = calculatedHours
		self.status = "completed"
		self.updatedAt = Date()
	}
	
	mutating func cancel() {
		self.status = "cancelled"
		self.updatedAt = Date()
	}
	
	// Initializer pour pointer l'arrivée
	init(userId: String, notes: String? = nil) {
		self.id = nil
		self.userId = userId
		self.arrival = Date()
		self.departure = nil
		self.hoursWorked = nil
		self.status = "active"
		self.notes = notes
		self.createdAt = Date()
		self.updatedAt = Date()
	}
}

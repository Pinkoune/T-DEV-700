import Vapor
import Fluent
import Foundation

final class TimeEntry: Model, Content, @unchecked Sendable {
	static let schema = "time_entries"
	
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "user_id")
	var user: User
	
	@Field(key: "arrival")
	var arrival: Date
	
	@OptionalField(key: "departure")
	var departure: Date?
	
	@OptionalField(key: "hours_worked")
	var hoursWorked: Double?
	
	@Field(key: "status")
	var status: String 
	
	@OptionalField(key: "notes")
	var notes: String?
	
	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?
	
	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?
	
	var calculatedHours: Double {
		guard let departure = departure else {
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
	
    func isLate(expectedArrivalTime: String) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: arrival)
        
        if hour < 12 {
            guard let expectedTime = parseTime(expectedArrivalTime) else { return false }
            let actualTime = getTimeComponents(from: arrival)
            return actualTime > expectedTime
        } 
        else if hour >= 12 {
            guard let expectedAfternoon = parseTime("13:00") else { return false }
            let actualTime = getTimeComponents(from: arrival)
            return actualTime > expectedAfternoon
        }
        
        return false
    }
    
    func lateMinutes(expectedArrivalTime: String) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: arrival)
        
        var targetTime: Int?
        
        if hour < 12 {
            targetTime = parseTime(expectedArrivalTime)
        } else if hour >= 12 {
            targetTime = parseTime("13:00")
        }
        
        guard let expected = targetTime else { return 0 }
        let actualTime = getTimeComponents(from: arrival)
        let diff = actualTime - expected
        return max(0, diff)
    }
	
	private func parseTime(_ timeString: String) -> Int? {
		let components = timeString.split(separator: ":").compactMap { Int($0) }
		guard components.count == 2 else { return nil }
		return components[0] * 60 + components[1]
	}
	
	private func getTimeComponents(from date: Date) -> Int {
		let calendar = Calendar.current
		let hour = calendar.component(.hour, from: date)
		let minute = calendar.component(.minute, from: date)
		return hour * 60 + minute
	}
	


	init() {}
	
	init(id: UUID? = nil, userId: UUID, notes: String? = nil) {
		self.id = id
		self.$user.id = userId
		self.arrival = Date()
		self.departure = nil
		self.hoursWorked = nil
		self.status = "active"
		self.notes = notes
	}
	
	func clockOut() {
		self.departure = Date()
		self.hoursWorked = calculatedHours
		self.status = "completed"
	}
	
	func cancel() {
		self.status = "cancelled"
	}
}

extension TimeEntry: Validatable {
	static func validations(_ validations: inout Validations) {
		validations.add("status", as: String.self, is: .in("active", "completed", "cancelled"))
	}
}

import Vapor
import Fluent

struct TimeEntryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let timeEntries = routes.grouped("timeentries")
        
        let protected = timeEntries.grouped(JWTAuthMiddleware())
        
        let manager = protected.grouped(ManagerMiddleware())
        manager.get(use: getAllTimeEntries)
        
        protected.post(use: createTimeEntry)
        protected.group(":timeEntryID") { timeEntry in
            timeEntry.get(use: getTimeEntry)
            timeEntry.put(use: updateTimeEntry)
            timeEntry.delete(use: deleteTimeEntry)
        }
        
        protected.post("clock-in", use: clockIn)
        protected.post("clock-out", ":timeEntryID", use: clockOut)
        protected.get("active", ":userID", use: getActiveTimeEntry)
        protected.get("by-user", ":userID", use: getTimeEntriesByUser)
        protected.get("stats", ":userID", use: getUserTimeStats)
        
        let clocks = routes.grouped("clocks").grouped(JWTAuthMiddleware())
        clocks.post(use: clock)
    }
    
    
    /// GET /timeentries - Récupère toutes les entrées de temps
    func getAllTimeEntries(req: Request) async throws -> [TimeEntryResponse] {
        let limit = req.query[Int.self, at: "limit"] ?? 50
        
        let timeEntries = try await TimeEntry.query(on: req.db)
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
        
        return timeEntries.map { TimeEntryResponse(from: $0) }
    }
    
    /// GET /timeentries/:timeEntryID - Récupère une entrée de temps spécifique
    func getTimeEntry(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID entrée de temps invalide")
        }
        
        guard let timeEntry = try await TimeEntry.query(on: req.db)
            .filter(\.$id == timeEntryID)
            .with(\.$user)
            .first()
        else {
            throw Abort(.notFound, reason: "Entrée de temps non trouvée")
        }
        
        return TimeEntryResponse(from: timeEntry)
    }
    
    /// POST /timeentries - Crée une nouvelle entrée de temps
    func createTimeEntry(req: Request) async throws -> TimeEntryResponse {
        try CreateTimeEntryRequest.validate(content: req)
        let timeEntryData = try req.content.decode(CreateTimeEntryRequest.self)
        
        guard let _ = try await User.find(timeEntryData.userId, on: req.db) else {
            throw Abort(.badRequest, reason: "Utilisateur non trouvé")
        }
        
        let activeEntry = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == timeEntryData.userId)
            .filter(\.$status == "active")
            .first()
        
        if activeEntry != nil {
            throw Abort(.conflict, reason: "L'utilisateur a déjà une entrée de temps active")
        }
        
        let timeEntry = TimeEntry(
            userId: timeEntryData.userId,
            notes: timeEntryData.notes
        )
        
        if let arrival = timeEntryData.arrival {
            timeEntry.arrival = arrival
        }
        
        try await timeEntry.save(on: req.db)
        try await timeEntry.$user.load(on: req.db)
        
        return TimeEntryResponse(from: timeEntry)
    }
    
    /// PUT /timeentries/:timeEntryID - Met à jour une entrée de temps
    func updateTimeEntry(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID entrée de temps invalide")
        }
        
        guard let timeEntry = try await TimeEntry.find(timeEntryID, on: req.db) else {
            throw Abort(.notFound, reason: "Entrée de temps non trouvée")
        }
        
        let updateData = try req.content.decode(UpdateTimeEntryRequest.self)
        
        if let arrival = updateData.arrival {
            timeEntry.arrival = arrival
        }
        if let departure = updateData.departure {
            timeEntry.departure = departure
            timeEntry.hoursWorked = timeEntry.calculatedHours
            if timeEntry.status == "active" {
                timeEntry.status = "completed"
            }
        }
        if let notes = updateData.notes {
            timeEntry.notes = notes
        }
        if let status = updateData.status {
            timeEntry.status = status
        }
        
        try await timeEntry.save(on: req.db)
        try await timeEntry.$user.load(on: req.db)
        
        return TimeEntryResponse(from: timeEntry)
    }
    
    /// DELETE /timeentries/:timeEntryID - Annule une entrée de temps
    func deleteTimeEntry(req: Request) async throws -> HTTPStatus {
        guard let timeEntryID = req.parameters.get("timeEntryID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID entrée de temps invalide")
        }
        
        guard let timeEntry = try await TimeEntry.find(timeEntryID, on: req.db) else {
            throw Abort(.notFound, reason: "Entrée de temps non trouvée")
        }
        
        timeEntry.status = "cancelled"
        try await timeEntry.save(on: req.db)
        
        return .noContent
    }
    
    
    /// POST /timeentries/clock-in - Pointer l'arrivée
    func clockIn(req: Request) async throws -> TimeEntryResponse {
        let clockInData = try req.content.decode(ClockInRequest.self)
        
        guard let _ = try await User.find(clockInData.userId, on: req.db) else {
            throw Abort(.badRequest, reason: "Utilisateur non trouvé")
        }
        
        let activeEntry = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == clockInData.userId)
            .filter(\.$status == "active")
            .first()
        
        if activeEntry != nil {
            throw Abort(.conflict, reason: "Vous avez déjà pointé votre arrivée")
        }
        
        let timeEntry = TimeEntry(
            userId: clockInData.userId,
            notes: clockInData.notes
        )
        
        try await timeEntry.save(on: req.db)
        try await timeEntry.$user.load(on: req.db)
        
        return TimeEntryResponse(from: timeEntry)
    }
    
    /// POST /timeentries/clock-out/:timeEntryID - Pointer la sortie
    func clockOut(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID entrée de temps invalide")
        }
        
        guard let timeEntry = try await TimeEntry.find(timeEntryID, on: req.db) else {
            throw Abort(.notFound, reason: "Entrée de temps non trouvée")
        }
        
        if timeEntry.status != "active" {
            throw Abort(.badRequest, reason: "Cette entrée de temps n'est pas active")
        }
        
        timeEntry.clockOut()
        
        try await timeEntry.save(on: req.db)
        try await timeEntry.$user.load(on: req.db)
        
        return TimeEntryResponse(from: timeEntry)
    }
    
    /// POST /clocks - Pointer l'arrivée ou la sortie automatiquement
    func clock(req: Request) async throws -> TimeEntryResponse {
        let clockData = try req.content.decode(ClockRequest.self)
        
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        if hour == 12 {
            throw Abort(.forbidden, reason: "Impossible de pointer entre 12h et 13h (Pause déjeuner)")
        }
        
        guard let _ = try await User.find(clockData.userId, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        let activeEntry = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == clockData.userId)
            .filter(\.$status == "active")
            .first()
        
        if let active = activeEntry {
            active.clockOut()
            try await active.save(on: req.db)
            try await active.$user.load(on: req.db)
            return TimeEntryResponse(from: active)
        } else {
            let timeEntry = TimeEntry(
                userId: clockData.userId,
                notes: nil
            )
            try await timeEntry.save(on: req.db)
            try await timeEntry.$user.load(on: req.db)
            return TimeEntryResponse(from: timeEntry)
        }
    }
    
    /// GET /timeentries/active/:userID - Récupère l'entrée de temps active d'un utilisateur
    func getActiveTimeEntry(req: Request) async throws -> ActiveTimeEntryResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        let activeEntry = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$status == "active")
            .with(\.$user)
            .first()
        
        if let timeEntry = activeEntry {
            return ActiveTimeEntryResponse(
                hasActiveEntry: true,
                timeEntry: TimeEntryResponse(from: timeEntry)
            )
        } else {
            return ActiveTimeEntryResponse(
                hasActiveEntry: false,
                timeEntry: nil
            )
        }
    }
    
    
    /// GET /timeentries/by-user/:userID - Entrées de temps par utilisateur
    func getTimeEntriesByUser(req: Request) async throws -> [TimeEntryResponse] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        let limit = req.query[Int.self, at: "limit"] ?? 20
        
        let timeEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()
        
        return timeEntries.map { TimeEntryResponse(from: $0) }
    }
    
    /// GET /timeentries/stats/:userID - Statistiques de temps d'un utilisateur
    func getUserTimeStats(req: Request) async throws -> UserTimeStatsResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        let timeEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$status == "completed")
            .all()
        
        var totalHours = 0.0
        var overtimeHours = 0.0
        let totalDays = timeEntries.count
        var overtimeDays = 0
        
        for timeEntry in timeEntries {
            if let hoursWorked = timeEntry.hoursWorked {
                totalHours += hoursWorked
                
                if timeEntry.isOvertime {
                    overtimeHours += timeEntry.overtimeHours
                    overtimeDays += 1
                }
            }
        }
        
        let averageHoursPerDay = totalDays > 0 ? totalHours / Double(totalDays) : 0.0
        
        return UserTimeStatsResponse(
            userId: userID.uuidString,
            totalHours: totalHours,
            totalDays: totalDays,
            averageHoursPerDay: averageHoursPerDay,
            overtimeHours: overtimeHours,
            overtimeDays: overtimeDays
        )
    }
}


struct CreateTimeEntryRequest: Content, Validatable {
    let userId: UUID
    let arrival: Date?
    let notes: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: UUID.self)
    }
}

struct UpdateTimeEntryRequest: Content {
    let arrival: Date?
    let departure: Date?
    let notes: String?
    let status: String?
}

struct ClockInRequest: Content, Validatable {
    let userId: UUID
    let notes: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: UUID.self)
    }
}

struct ClockRequest: Content, Validatable {
    let userId: UUID
    
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: UUID.self)
    }
}

struct TimeEntryResponse: Content {
    let id: UUID?
    let userId: UUID
    let userName: String
    let arrival: Date
    let departure: Date?
    let hoursWorked: Double?
    let status: String
    let notes: String?
    let isOvertime: Bool
    let overtimeHours: Double
    let createdAt: Date?
    
    init(from timeEntry: TimeEntry) {
        self.id = timeEntry.id
        self.userId = timeEntry.$user.id
        self.userName = timeEntry.user.fullName
        self.arrival = timeEntry.arrival
        self.departure = timeEntry.departure
        self.hoursWorked = timeEntry.hoursWorked
        self.status = timeEntry.status
        self.notes = timeEntry.notes
        self.isOvertime = timeEntry.isOvertime
        self.overtimeHours = timeEntry.overtimeHours
        self.createdAt = timeEntry.createdAt
    }
}

struct UserTimeStatsResponse: Content {
    let userId: String
    let totalHours: Double
    let totalDays: Int
    let averageHoursPerDay: Double
    let overtimeHours: Double
    let overtimeDays: Int
}

struct ActiveTimeEntryResponse: Content {
    let hasActiveEntry: Bool
    let timeEntry: TimeEntryResponse?
}

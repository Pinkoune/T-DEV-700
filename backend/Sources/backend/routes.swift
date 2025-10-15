import Vapor
import Fluent

func routes(_ app: Application) throws {
    app.get { req async -> APIInfoResponse in
        return APIInfoResponse(
            message: "T-DEV-700 - McTime",
            version: "1.0.0",
            status: "running",
            database: "PostgreSQL",
        )
    }

    app.get("health") { req async -> HealthResponse in
        do {
            _ = try await User.query(on: req.db).count()
            return HealthResponse(
                status: "healthy",
                database: "connected",
                timestamp: Date()
            )
        } catch {
            return HealthResponse(
                status: "unhealthy",
                database: "disconnected",
                timestamp: Date(),
                error: error.localizedDescription
            )
        }
    }
    
    // Controllers
    try app.register(collection: AuthController())
    try app.register(collection: UserController())
    try app.register(collection: PerformanceController())
    try app.register(collection: TimeEntryController())
    try app.register(collection: TeamController())
    
    // GET /users/:id/clocks - Pointages des utilisateurs 
    app.get("users", ":userID", "clocks") { req async throws -> [TimeEntryResponse] in
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        let timeEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .with(\.$user)
            .sort(\.$arrival, .descending)
            .all()
        
        return timeEntries.map { TimeEntryResponse(from: $0) }
    }
    
    // GET /reports - Rapport global 
    app.get("reports") { req async throws -> ReportsResponse in
        let activeUsers = try await User.query(on: req.db)
            .filter(\.$isActive == true)
            .count()
        
        let activeTeams = try await Team.query(on: req.db)
            .filter(\.$isActive == true)
            .count()
        
        let currentlyWorking = try await TimeEntry.query(on: req.db)
            .filter(\.$status == "active")
            .count()
        
        // KPI : Concernant les heures travaillées par nos employés chaque mois. 
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let completedEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$status == "completed")
            .filter(\.$createdAt >= startOfMonth)
            .all()
        
        let totalHoursThisMonth = completedEntries.reduce(0.0) { $0 + ($1.hoursWorked ?? 0) }
        
        // KPI : Moyenne de performance des employés
        let performances = try await Performance.query(on: req.db)
            .filter(\.$createdAt >= startOfMonth)
            .all()
        
        let averagePerformance = performances.isEmpty ? 0.0 : performances.map { $0.index }.reduce(0, +) / Double(performances.count)
        
        return ReportsResponse(
            activeUsers: activeUsers,
            activeTeams: activeTeams,
            currentlyWorking: currentlyWorking,
            totalHoursThisMonth: totalHoursThisMonth,
            averagePerformance: averagePerformance,
            totalTimeEntries: completedEntries.count,
            period: "month",
            generatedAt: Date()
        )
    }
    
    // Statistiques globales par mois
    app.get("stats") { req async throws -> GlobalStatsResponse in
        let activeUsers = try await User.query(on: req.db)
            .filter(\.$isActive == true)
            .count()
        
        let activeTeams = try await Team.query(on: req.db)
            .filter(\.$isActive == true)
            .count()
        
        let currentlyWorking = try await TimeEntry.query(on: req.db)
            .filter(\.$status == "active")
            .count()
        
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let performancesThisMonth = try await Performance.query(on: req.db)
            .filter(\.$createdAt >= startOfMonth)
            .count()
        
        return GlobalStatsResponse(
            activeUsers: activeUsers,
            activeTeams: activeTeams,
            currentlyWorking: currentlyWorking,
            performancesThisMonth: performancesThisMonth,
            timestamp: Date()
        )
    }
}

// Réponse pour les Models

struct APIInfoResponse: Content {
    let message: String
    let version: String
    let status: String
    let database: String
    let endpoints: APIEndpoints
}

struct APIEndpoints: Content {
    let health: String
    let auth: String
    let users: String
    let teams: String
    let clocks: String
    let reports: String
    let timeentries: String
    let performances: String
    let stats: String
}

struct HealthResponse: Content {
    let status: String
    let database: String
    let timestamp: Date
    let error: String?
    
    init(status: String, database: String, timestamp: Date, error: String? = nil) {
        self.status = status
        self.database = database
        self.timestamp = timestamp
        self.error = error
    }
}

struct GlobalStatsResponse: Content {
    let activeUsers: Int
    let activeTeams: Int
    let currentlyWorking: Int
    let performancesThisMonth: Int
    let timestamp: Date
}

struct ReportsResponse: Content {
    let activeUsers: Int
    let activeTeams: Int
    let currentlyWorking: Int
    let totalHoursThisMonth: Double
    let averagePerformance: Double
    let totalTimeEntries: Int
    let period: String
    let generatedAt: Date
}

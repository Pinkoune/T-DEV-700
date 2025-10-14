import Vapor
import Fluent

func routes(_ app: Application) throws {
    // Route de base pour vérifier que l'API fonctionne
    app.get { req async -> APIInfoResponse in
        return APIInfoResponse(
            message: "Time Management API - PostgreSQL",
            version: "2.0.0",
            status: "running",
            database: "PostgreSQL",
            endpoints: APIEndpoints(
                health: "/health",
                users: "/users",
                teams: "/teams",
                timeentries: "/timeentries",
                performances: "/performances",
                stats: "/stats"
            )
        )
    }

    // Health check
    app.get("health") { req async -> HealthResponse in
        // Vérifier la connexion à la base de données
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
    
    // Controllers - Temporairement commentés jusqu'à migration complète
    // TODO: Migrer les controllers vers Fluent
    // try app.register(collection: UserController())
    // try app.register(collection: TeamController())
    // try app.register(collection: TimeEntryController())
    // try app.register(collection: PerformanceController())
    
    // Route pour les statistiques globales avec PostgreSQL
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
    let users: String
    let teams: String
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

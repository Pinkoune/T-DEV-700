import Vapor

func routes(_ app: Application) throws {
    // Route de base pour vérifier que l'API fonctionne
    app.get { req async -> APIInfoResponse in
        return APIInfoResponse(
            message: "Time Management API",
            version: "1.0.0",
            status: "running",
            endpoints: APIEndpoints(
                users: "/api/users",
                teams: "/api/teams",
                timeentries: "/api/timeentries",
                performances: "/api/performances"
            )
        )
    }

    app.get("health") { req async -> String in
        "API is healthy!"
    }
    
    // Enregistrement des contrôleurs simplifiés (pour démonstration)
    try app.register(collection: SimpleUserController())
    try app.register(collection: SimpleTimeEntryController())
    
    // Note: Les contrôleurs complets avec Firebase sont disponibles mais commentés
    // try app.register(collection: UserController())
    // try app.register(collection: TeamController())
    // try app.register(collection: TimeEntryController())
    // try app.register(collection: PerformanceController())
    
    // Route pour les statistiques globales (version simplifiée)
    app.get("api", "stats") { req async throws -> GlobalStatsResponse in
        let stats = await MockDataService.shared.getGlobalStats()
        
        return GlobalStatsResponse(
            activeUsers: stats.activeUsers,
            activeTeams: stats.activeTeams,
            currentlyWorking: stats.currentlyWorking,
            performancesThisMonth: stats.performancesThisMonth,
            timestamp: Date()
        )
    }
}

// Réponse pour les Models

struct APIInfoResponse: Content {
    let message: String
    let version: String
    let status: String
    let endpoints: APIEndpoints
}

struct APIEndpoints: Content {
    let users: String
    let teams: String
    let timeentries: String
    let performances: String
}

struct GlobalStatsResponse: Content {
    let activeUsers: Int
    let activeTeams: Int
    let currentlyWorking: Int
    let performancesThisMonth: Int
    let timestamp: Date
}

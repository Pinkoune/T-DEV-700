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
    
    // Enregistrement des contrôleurs Firebase
    try app.register(collection: AuthController())
    try app.register(collection: UserController())
    try app.register(collection: TeamController())
    try app.register(collection: TimeEntryController())
    try app.register(collection: PerformanceController())
    
    // Route pour les statistiques globales
    app.get("api", "stats") { req async throws -> GlobalStatsResponse in
        let firestore = req.application.firestore
        
        do {
            // Compte les utilisateurs actifs
            let usersSnapshot = try await firestore.collection("users")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            // Compte les équipes actives
            let teamsSnapshot = try await firestore.collection("teams")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            // Compte les entrées de temps actives
            let activeTimeEntriesSnapshot = try await firestore.collection("timeEntries")
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
            // Compte les performances ce mois-ci
            let calendar = Calendar.current
            let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            let performancesSnapshot = try await firestore.collection("performances")
                .whereField("createdAt", isGreaterThanOrEqualTo: startOfMonth)
                .getDocuments()
            
            return GlobalStatsResponse(
                activeUsers: usersSnapshot.documents.count,
                activeTeams: teamsSnapshot.documents.count,
                currentlyWorking: activeTimeEntriesSnapshot.documents.count,
                performancesThisMonth: performancesSnapshot.documents.count,
                timestamp: Date()
            )
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des statistiques: \(error.localizedDescription)")
        }
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

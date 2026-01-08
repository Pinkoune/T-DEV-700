import Vapor
import Fluent
import VaporToOpenAPI

func routes(_ app: Application) throws {
    
    // MARK: - Swagger Documentation
    app.get("swagger.json") { req in
        req.application.routes.openAPI(
            info: InfoObject(
                title: "McTime API",
                description: """
                    API de gestion du temps - T-DEV-700
                    
                    ## Authentification
                    La plupart des endpoints nécessitent un token JWT dans le header `Authorization: Bearer <token>`.
                    
                    ## Codes d'erreur communs
                    - `400` Bad Request - Paramètres invalides
                    - `401` Unauthorized - Token manquant ou invalide
                    - `403` Forbidden - Permissions insuffisantes
                    - `404` Not Found - Ressource non trouvée
                    - `500` Internal Server Error - Erreur serveur
                    """,
                version: "1.0.0"
            )
        )
    }

    // MARK: - Health Check
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
    .openAPI(
        tags: "Système",
        summary: "Health check",
        description: """
            Vérifie l'état de santé de l'API et la connexion à la base de données.
            
            **Utilisation:** Utilisez cet endpoint pour monitorer la disponibilité de l'API.
            
            **Réponses possibles:**
            - `status: "healthy"` - L'API fonctionne correctement
            - `status: "unhealthy"` - Problème détecté (voir champ `error`)
            """,
        response: .type(HealthResponse.self),
        responseContentType: .application(.json),
        responseDescription: "État de santé de l'API"
    )

    // MARK: - Controllers
    try app.register(collection: AuthController())
    try app.register(collection: UserController())
    try app.register(collection: TimeEntryController())
    try app.register(collection: TeamController())
    try app.register(collection: DashboardController())

    // MARK: - User Clocks (Time Entries)
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
    .openAPI(
        tags: "Pointages",
        summary: "Récupérer les pointages d'un utilisateur",
        description: """
            Récupère tous les pointages (time entries) d'un utilisateur spécifique.
            
            **Paramètres:**
            - `userID` (path) - UUID de l'utilisateur
            
            **Exemple de requête:**
            ```
            GET /users/550e8400-e29b-41d4-a716-446655440000/clocks
            ```
            
            **Tri:** Les résultats sont triés par date d'arrivée décroissante (plus récent en premier).
            """,
        response: .type([TimeEntryResponse].self),
        responseContentType: .application(.json),
        responseDescription: "Liste des pointages de l'utilisateur"
    )

    // MARK: - Reports (KPIs)
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

        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let completedEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$status == "completed")
            .filter(\.$createdAt >= startOfMonth)
            .all()

        let totalHoursThisMonth = completedEntries.reduce(0.0) { $0 + ($1.hoursWorked ?? 0) }

        return ReportsResponse(
            activeUsers: activeUsers,
            activeTeams: activeTeams,
            currentlyWorking: currentlyWorking,
            totalHoursThisMonth: totalHoursThisMonth,
            totalTimeEntries: completedEntries.count,
            period: "month",
            generatedAt: Date()
        )
    }
    .openAPI(
        tags: "Rapports",
        summary: "Récupérer les KPIs globaux",
        description: """
            Récupère les indicateurs clés de performance (KPIs) de l'entreprise.
            
            **KPIs retournés:**
            - `activeUsers` - Nombre d'utilisateurs actifs
            - `activeTeams` - Nombre d'équipes actives
            - `currentlyWorking` - Nombre d'employés actuellement en poste
            - `totalHoursThisMonth` - Total des heures travaillées ce mois
            - `averagePerformance` - Moyenne de performance des employés
            - `totalTimeEntries` - Nombre total de pointages complétés ce mois
            
            **Période:** Les données sont calculées pour le mois en cours.
            
            **Exemple de requête:**
            ```
            GET /reports
            Authorization: Bearer <token>
            ```
            """,
        response: .type(ReportsResponse.self),
        responseContentType: .application(.json),
        responseDescription: "Rapport contenant tous les KPIs"
    )

    // MARK: - Global Stats
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

        return GlobalStatsResponse(
            activeUsers: activeUsers,
            activeTeams: activeTeams,
            currentlyWorking: currentlyWorking,
            timestamp: Date()
        )
    }
    .openAPI(
        tags: "Statistiques",
        summary: "Récupérer les statistiques globales",
        description: """
            Récupère les statistiques globales du système en temps réel.
            
            **Statistiques retournées:**
            - `activeUsers` - Nombre d'utilisateurs actifs dans le système
            - `activeTeams` - Nombre d'équipes actives
            - `currentlyWorking` - Nombre d'employés actuellement pointés (status: active)
            - `performancesThisMonth` - Nombre d'évaluations de performance ce mois
            - `timestamp` - Date et heure de génération des stats
            
            **Exemple de requête:**
            ```
            GET /stats
            Authorization: Bearer <token>
            ```
            
            **Cas d'usage:** Dashboard temps réel, monitoring, tableaux de bord.
            """,
        response: .type(GlobalStatsResponse.self),
        responseContentType: .application(.json),
        responseDescription: "Statistiques globales du système"
    )
}

// MARK: - Response Models

struct APIInfoResponse: Content, WithExample {
    let message: String
    let version: String
    let status: String
    let database: String
    
    static var example: APIInfoResponse {
        APIInfoResponse(
            message: "McTime API",
            version: "1.0.0",
            status: "running",
            database: "connected"
        )
    }
}

struct APIEndpoints: Content, WithExample {
    let health: String
    let auth: String
    let users: String
    let teams: String
    let clocks: String
    let reports: String
    let timeentries: String
    let performances: String
    let stats: String
    
    static var example: APIEndpoints {
        APIEndpoints(
            health: "/health",
            auth: "/auth",
            users: "/users",
            teams: "/teams",
            clocks: "/users/{userID}/clocks",
            reports: "/reports",
            timeentries: "/timeentries",
            performances: "/performances",
            stats: "/stats"
        )
    }
}

struct HealthResponse: Content, WithExample {
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
    
    static var example: HealthResponse {
        HealthResponse(
            status: "healthy",
            database: "connected",
            timestamp: Date()
        )
    }
}

struct GlobalStatsResponse: Content, WithExample {
    let activeUsers: Int
    let activeTeams: Int
    let currentlyWorking: Int
    let timestamp: Date
    
    static var example: GlobalStatsResponse {
        GlobalStatsResponse(
            activeUsers: 42,
            activeTeams: 5,
            currentlyWorking: 28,
            performancesThisMonth: 156,
            timestamp: Date()
        )
    }
}

struct ReportsResponse: Content, WithExample {
    let activeUsers: Int
    let activeTeams: Int
    let currentlyWorking: Int
    let totalHoursThisMonth: Double
    let totalTimeEntries: Int
    let period: String
    let generatedAt: Date
    
    static var example: ReportsResponse {
        ReportsResponse(
            activeUsers: 42,
            activeTeams: 5,
            currentlyWorking: 28,
            totalHoursThisMonth: 1250.5,
            averagePerformance: 85.3,
            totalTimeEntries: 892,
            period: "month",
            generatedAt: Date()
        )
    }
}

// MARK: - Error Response Model

struct ErrorResponse: Content, WithExample {
    let error: Bool
    let reason: String
    let status: Int
    
    static var example: ErrorResponse {
        ErrorResponse(
            error: true,
            reason: "ID utilisateur invalide",
            status: 400
        )
    }
}
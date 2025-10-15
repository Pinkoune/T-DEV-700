import Vapor

func routes(_ app: Application) throws {
    // Route de base pour vérifier que l'API fonctionne
    app.get { req async -> APIInfoResponse in
        return APIInfoResponse(
            message: "Time Management API - JWT Simple",
            version: "1.0.0",
            status: "running",
            endpoints: APIEndpoints(
                login: "/login",
                users: "/api/users",
                health: "/health"
            )
        )
    }
    
    app.get("health") { req async -> String in
        "API is healthy with JWT!"
    }
    
    // Enregistrement du contrôleur utilisateur
    try app.register(collection: UserController())
}

// Structures de réponse

struct APIInfoResponse: Content {
    let message: String
    let version: String
    let status: String
    let endpoints: APIEndpoints
}

struct APIEndpoints: Content {
    let login: String
    let users: String
    let health: String
}

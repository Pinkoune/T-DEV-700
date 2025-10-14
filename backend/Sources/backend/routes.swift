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
    try app.register(collection: UserController())
    try app.register(collection: TeamController())
    try app.register(collection: TimeEntryController())
    try app.register(collection: PerformanceController())

    // Routes d'authentification (non protégées)
    app.post("login") { req async throws -> [String: String] in
        try LoginRequest.validate(content: req)
        let loginData = try req.content.decode(LoginRequest.self)

        // Authentifier l'utilisateur
        guard let user = try await authenticateUser(
            email: loginData.email,
            password: loginData.password,
            firestore: req.application.firestore
        ) else {
            throw Abort(.unauthorized, reason: "Email ou mot de passe incorrect")
        }

        // Création du payload JWT
        let payload = UserPayload(
            sub: .init(value: user.id!),
            exp: .init(value: Date().addingTimeInterval(3600)), // 1 heure
            iat: .init(value: Date()),
            iss: .init(value: "https://monurlsecure.com"),
            aud: .init(value: "app-mobile"),
            userId: UUID(uuidString: user.id!) ?? UUID(),
            roles: [user.role],
            isVerified: user.isActive
        )

        let token = try await req.jwt.sign(payload, kid: "cle-eddsa-v1")

        return [
            "token": token,
            "user_id": user.id!,
            "expires_in": "3600"
        ]
    }

    app.post("refresh") { req async throws -> [String: String] in
        // Vérifier le token existant (même expiré)
        guard let token = req.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Token manquant")
        }
        
        // Décoder sans vérifier l'expiration
        let payload = try req.jwt.decode(token, as: UserPayload.self)
        
        // Vérifier que l'utilisateur existe toujours
        let firestore = req.application.firestore
        let userDoc = try await firestore.collection("users").document(payload.userId.uuidString).getDocument()
        
        guard userDoc.exists else {
            throw Abort(.unauthorized, reason: "Utilisateur non trouvé")
        }
        
        // Créer un nouveau token
        let newPayload = UserPayload(
            sub: payload.sub,
            exp: .init(value: Date().addingTimeInterval(3600)),
            iat: .init(value: Date()),
            iss: payload.iss,
            aud: payload.aud,
            userId: payload.userId,
            roles: payload.roles,
            isVerified: payload.isVerified
        )
        
        let newToken = try await req.jwt.sign(newPayload, kid: "cle-eddsa-v1")
        
        return [
            "token": newToken,
            "expires_in": "3600"
        ]
    }

    // Route pour les statistiques globales (protégée)
    let protectedRoutes = app.grouped(JWTAuthMiddleware())
    protectedRoutes.get("api", "stats") { req async throws -> GlobalStatsResponse in
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

// Structure pour la requête de login
struct LoginRequest: Content, Validatable {
    let email: String
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty && .count(6...))
    }
}

// Fonction d'authentification
func authenticateUser(email: String, password: String, firestore: Firestore) async
    throws -> User? {
        let snapshot = try await firestore.collection("users")
            .whereField("email", isEqualTo: email)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        guard let document = snapshot.documents.first,
              var user = try? document.data(as: User.self) else {
            return nil
        }

        // Mettre en place vérification hash du mot de passe avec bcrypt
        if password == "temp_password" {
            user.id = document.documentID
            return user
        }

        return nil
    }


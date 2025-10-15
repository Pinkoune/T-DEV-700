import Vapor
import BCrypt

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        // Routes d'authentification publiques
        routes.post("login", use: login)
        routes.post("refresh", use: refreshToken)
        
        // Routes protégées
        let protected = routes.grouped(JWTAuthenticator())
        protected.post("logout", use: logout)
        
        let users = protected.grouped("api", "users")
        users.get(use: getAllUsers)
        users.post(use: createUser)
        
        users.group(":userID") { user in
            user.get(use: getUser)
            user.put(use: updateUser)
            user.delete(use: deleteUser)
        }
    }
    
    // MARK: - Authentification
    
    func login(req: Request) async throws -> LoginResponse {
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        // Pour l'instant, utilisateur de test simple
        let user = User(
            firstName: "Test",
            lastName: "User",
            email: loginRequest.email,
            phone: "1234567890",
            role: "admin"
        )
        
        // Vérification simple du mot de passe
        guard loginRequest.password == "temp_password" else {
            throw Abort(.unauthorized, reason: "Credentials invalides")
        }
        
        // Génération du token JWT
        let jwtService = JWTService(application: req.application)
        let token = try jwtService.generateToken(for: user)
        
        return LoginResponse(
            accessToken: token,
            tokenType: "Bearer",
            expiresIn: 3600,
            user: UserResponse(from: user)
        )
    }
    
    func refreshToken(req: Request) async throws -> TokenRefreshResponse {
        let refreshRequest = try req.content.decode(TokenRefreshRequest.self)
        
        // Vérifier le token existant
        let jwtService = JWTService(application: req.application)
        let payload = try jwtService.verifyToken(refreshRequest.refreshToken)
        
        // Créer un utilisateur depuis le payload
        let user = User(
            firstName: "User",
            lastName: "From Token",
            email: payload.email,
            phone: "1234567890",
            role: payload.role
        )
        
        // Générer un nouveau token
        let newToken = try jwtService.generateToken(for: user)
        
        return TokenRefreshResponse(
            accessToken: newToken,
            tokenType: "Bearer",
            expiresIn: 3600
        )
    }
    
    func logout(req: Request) async throws -> HTTPStatus {
        let payload = try req.requireAuthentication()
        
        req.logger.info("Déconnexion de l'utilisateur: \(payload.email)")
        
        return .noContent
    }
    
    // MARK: - CRUD Simplifié
    
    func getAllUsers(req: Request) async throws -> [UserResponse] {
        // Vérifier l'authentification
        let payload = try req.requireAuthentication()
        
        // Utilisateurs de test
        let users = [
            User(firstName: "Admin", lastName: "User", email: "admin@example.com", phone: "1234567890", role: "admin"),
            User(firstName: "Manager", lastName: "User", email: "manager@example.com", phone: "1234567890", role: "manager"),
            User(firstName: "Employee", lastName: "User", email: "employee@example.com", phone: "1234567890", role: "employee")
        ]
        
        return users.map { UserResponse(from: $0) }
    }
    
    func createUser(req: Request) async throws -> UserResponse {
        let payload = try req.requireAuthentication()
        
        // Vérifier les permissions
        guard payload.permissions.contains("manage:users") else {
            throw Abort(.forbidden, reason: "Permissions insuffisantes")
        }
        
        let createRequest = try req.content.decode(CreateUserRequest.self)
        
        let user = User(
            firstName: createRequest.firstName,
            lastName: createRequest.lastName,
            email: createRequest.email,
            phone: createRequest.phone,
            role: createRequest.role ?? "employee"
        )
        
        return UserResponse(from: user)
    }
    
    func getUser(req: Request) async throws -> UserResponse {
        let payload = try req.requireAuthentication()
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        // Utilisateur de test
        let user = User(
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            phone: "1234567890",
            role: "employee"
        )
        
        return UserResponse(from: user)
    }
    
    func updateUser(req: Request) async throws -> UserResponse {
        let payload = try req.requireAuthentication()
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let updateRequest = try req.content.decode(UpdateUserRequest.self)
        
        // Utilisateur mis à jour (simulation)
        let user = User(
            firstName: updateRequest.firstName ?? "Updated",
            lastName: updateRequest.lastName ?? "User",
            email: updateRequest.email ?? "updated@example.com",
            phone: updateRequest.phone ?? "1234567890",
            role: updateRequest.role ?? "employee"
        )
        
        return UserResponse(from: user)
    }
    
    func deleteUser(req: Request) async throws -> HTTPStatus {
        let payload = try req.requireAuthentication()
        
        // Vérifier les permissions admin
        guard payload.role == "admin" else {
            throw Abort(.forbidden, reason: "Seuls les admins peuvent supprimer des utilisateurs")
        }
        
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        req.logger.info("Utilisateur supprimé: \(userID)")
        
        return .noContent
    }
}

// MARK: - Structures de Requête/Réponse

struct LoginRequest: Content {
    let email: String
    let password: String
}

struct LoginResponse: Content {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let user: UserResponse
}

struct TokenRefreshRequest: Content {
    let refreshToken: String
}

struct TokenRefreshResponse: Content {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
}

struct CreateUserRequest: Content {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let role: String?
}

struct UpdateUserRequest: Content {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let role: String?
}

struct UserResponse: Content {
    let id: String?
    let firstName: String
    let lastName: String
    let fullName: String
    let email: String
    let phone: String
    let role: String
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(from user: User) {
        self.id = user.id
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.fullName = user.fullName
        self.email = user.email
        self.phone = user.phone
        self.role = user.role
        self.isActive = user.isActive
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }
}

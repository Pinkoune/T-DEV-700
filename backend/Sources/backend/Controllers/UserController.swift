import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        
        // Routes protégées par JWT
        let protected = users.grouped(JWTAuthMiddleware())
        
        // Routes admin seulement
        let admin = protected.grouped(AdminMiddleware())
        admin.get(use: getAllUsers)
        admin.post(use: createUser)
        admin.delete(":userID", use: deleteUser)
        admin.get("by-role", ":role", use: getUsersByRole)
        admin.get("active", use: getActiveUsers)
        
        // Routes accessibles par l'utilisateur lui-même ou admin
        protected.group(":userID") { user in
            user.get(use: getUser)
            user.put(use: updateUser)
            user.get("profile", use: getUserProfile)
            user.get("teams", use: getUserTeams)
            user.get("timeentries", use: getUserTimeEntries)
            user.get("performances", use: getUserPerformances)
        }
        
        // Routes de recherche (authentifié)
        protected.get("search", use: searchUsers)
    }
    
    // MARK: - CRUD Operations
    
    /// GET /users - Récupère tous les utilisateurs
    func getAllUsers(req: Request) async throws -> [UserResponse] {
        let limit = req.query[Int.self, at: "limit"] ?? 100
        
        let users = try await User.query(on: req.db)
            .limit(limit)
            .all()
        
        return users.map { UserResponse(from: $0) }
    }
    
    /// GET /users/:userID - Récupère un utilisateur spécifique
    func getUser(req: Request) async throws -> UserResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        return UserResponse(from: user)
    }
    
    /// POST /users - Crée un nouvel utilisateur
    func createUser(req: Request) async throws -> UserResponse {
        try CreateUserRequest.validate(content: req)
        let userData = try req.content.decode(CreateUserRequest.self)
        
        // Vérifier que l'email n'existe pas déjà
        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == userData.email.lowercased())
            .first()
        
        if existingUser != nil {
            throw Abort(.conflict, reason: "Un utilisateur avec cet email existe déjà")
        }
        
        // Générer un mot de passe par défaut hashé
        let defaultPassword = "Welcome2024!"
        let passwordHash = try req.password.hash(defaultPassword)
        
        // Créer le nouvel utilisateur
        let user = User(
            firstName: userData.firstName,
            lastName: userData.lastName,
            email: userData.email.lowercased(),
            passwordHash: passwordHash,
            phone: userData.phone,
            role: userData.role ?? "employee",
            department: userData.department,
            position: userData.position,
            weeklyHoursTarget: userData.weeklyHoursTarget ?? 35.0
        )
        
        try await user.save(on: req.db)
        
        return UserResponse(from: user)
    }
    
    /// PUT /users/:userID - Met à jour un utilisateur
    func updateUser(req: Request) async throws -> UserResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        let updateData = try req.content.decode(UpdateUserRequest.self)
        
        // Mise à jour des champs modifiés
        if let firstName = updateData.firstName {
            user.firstName = firstName
        }
        if let lastName = updateData.lastName {
            user.lastName = lastName
        }
        if let email = updateData.email {
            // Vérifier que le nouvel email n'existe pas déjà
            let existingUser = try await User.query(on: req.db)
                .filter(\.$email == email.lowercased())
                .filter(\.$id != userID)
                .first()
            
            if existingUser != nil {
                throw Abort(.conflict, reason: "Un utilisateur avec cet email existe déjà")
            }
            user.email = email.lowercased()
        }
        if let phone = updateData.phone {
            user.phone = phone
        }
        if let role = updateData.role {
            user.role = role
        }
        if let department = updateData.department {
            user.department = department
        }
        if let position = updateData.position {
            user.position = position
        }
        if let weeklyHoursTarget = updateData.weeklyHoursTarget {
            user.weeklyHoursTarget = weeklyHoursTarget
        }
        if let isActive = updateData.isActive {
            user.isActive = isActive
        }
        
        try await user.save(on: req.db)
        
        return UserResponse(from: user)
    }
    
    /// DELETE /users/:userID - Désactive un utilisateur (soft delete)
    func deleteUser(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        // Soft delete : marquer comme inactif au lieu de supprimer
        user.isActive = false
        try await user.save(on: req.db)
        
        return .noContent
    }
    
    // MARK: - Specialized Routes
    
    /// GET /users/:userID/profile - Profil complet de l'utilisateur
    func getUserProfile(req: Request) async throws -> UserProfileResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        // Charger les relations
        try await user.$timeEntries.load(on: req.db)
        try await user.$performances.load(on: req.db)
        
        return UserProfileResponse(from: user)
    }
    
    /// GET /users/:userID/teams - Équipes de l'utilisateur
    func getUserTeams(req: Request) async throws -> [UserTeamResponse] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let _ = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        // Trouver toutes les équipes où l'utilisateur est membre
        let allTeams = try await Team.query(on: req.db).all()
        let teams = allTeams.filter { $0.isMember(userID) }
        
        return teams.map { UserTeamResponse(from: $0) }
    }
    
    /// GET /users/:userID/timeentries - Entrées de temps de l'utilisateur
    func getUserTimeEntries(req: Request) async throws -> [TimeEntry] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let _ = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        let timeEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .with(\.$user)
            .sort(\.$arrival, .descending)
            .all()
        
        return timeEntries
    }
    
    /// GET /users/:userID/performances - Performances de l'utilisateur
    func getUserPerformances(req: Request) async throws -> [PerformanceResponse] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let _ = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        let performances = try await Performance.query(on: req.db)
            .filter(\.$user.$id == userID)
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .all()
        
        return performances.map { PerformanceResponse(from: $0) }
    }
    
    /// GET /users/search?q=query - Recherche d'utilisateurs
    func searchUsers(req: Request) async throws -> [UserResponse] {
        guard let query = req.query[String.self, at: "q"] else {
            throw Abort(.badRequest, reason: "Paramètre de recherche 'q' manquant")
        }
        
        let searchTerm = "%\(query.lowercased())%"
        
        let users = try await User.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$firstName, .custom("ILIKE"), searchTerm)
                group.filter(\.$lastName, .custom("ILIKE"), searchTerm)
                group.filter(\.$email, .custom("ILIKE"), searchTerm)
            }
            .all()
        
        return users.map { UserResponse(from: $0) }
    }
    
    /// GET /users/by-role/:role - Utilisateurs par rôle
    func getUsersByRole(req: Request) async throws -> [UserResponse] {
        guard let role = req.parameters.get("role") else {
            throw Abort(.badRequest, reason: "Rôle manquant")
        }
        
        let users = try await User.query(on: req.db)
            .filter(\.$role == role)
            .all()
        
        return users.map { UserResponse(from: $0) }
    }
    
    /// GET /users/active - Utilisateurs actifs uniquement
    func getActiveUsers(req: Request) async throws -> [UserResponse] {
        let users = try await User.query(on: req.db)
            .filter(\.$isActive == true)
            .all()
        
        return users.map { UserResponse(from: $0) }
    }
}

// MARK: - Request/Response Models

struct CreateUserRequest: Content, Validatable {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let role: String?
    let department: String?
    let position: String?
    let weeklyHoursTarget: Double?
    
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty && .count(2...50))
        validations.add("lastName", as: String.self, is: !.empty && .count(2...50))
        validations.add("email", as: String.self, is: .email)
        validations.add("phone", as: String.self, is: .count(10...15))
    }
}

struct UpdateUserRequest: Content {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let role: String?
    let department: String?
    let position: String?
    let weeklyHoursTarget: Double?
    let isActive: Bool?
}

struct UserResponse: Content {
    let id: UUID?
    let firstName: String
    let lastName: String
    let fullName: String
    let email: String
    let phone: String
    let role: String
    let displayRole: String
    let department: String?
    let position: String?
    let weeklyHoursTarget: Double
    let isActive: Bool
    let hireDate: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from user: User) {
        self.id = user.id
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.fullName = user.fullName
        self.email = user.email
        self.phone = user.phone
        self.role = user.role
        self.displayRole = user.displayRole
        self.department = user.department
        self.position = user.position
        self.weeklyHoursTarget = user.weeklyHoursTarget
        self.isActive = user.isActive
        self.hireDate = user.hireDate
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }
}

struct UserProfileResponse: Codable {
    let user: UserResponse
    let stats: UserStats
    
    init(from user: User) {
        self.user = UserResponse(from: user)
        self.stats = UserStats(
            totalTimeEntries: user.timeEntries.count,
            totalPerformances: user.performances.count,
            averagePerformance: user.performances.isEmpty ? 0 : user.performances.map { $0.index }.reduce(0, +) / Double(user.performances.count)
        )
    }
}

extension UserProfileResponse: Content {}

struct UserStats: Content {
    let totalTimeEntries: Int
    let totalPerformances: Int
    let averagePerformance: Double
}

struct UserTeamResponse: Content {
    let id: UUID?
    let name: String
    let description: String
    let memberCount: Int
    let managerId: UUID
    let color: String
    let isActive: Bool
    
    init(from team: Team) {
        self.id = team.id
        self.name = team.name
        self.description = team.description
        self.memberCount = team.memberCount
        self.managerId = team.managerId
        self.color = team.color
        self.isActive = team.isActive
    }
}

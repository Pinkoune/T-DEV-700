import Vapor
import FirebaseFirestore
import FirebaseFirestoreSwift

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        
        // Route protégées par JWT
        let protected = users.grouped(JWTAuthMiddleware())
        
        // Application de la protection à toutes les routes
        protected.get(use: getAllUsers)
        protected.post(use: createUser)
        protected.group(":userID") { user in
            user.get(use: getUser)
            user.put(use: updateUser)
            user.delete(use: deleteUser)
            user.get("profile", use: getUserProfile)
            user.get("teams", use: getUserTeams)
            user.get("timeentries", use: getUserTimeEntries)
            user.get("performance", use: getUserPerformance)
        }
        
        protected.get("search", use: searchUsers)
        protected.get("by-role", ":role", use: getUsersByRole)
        protected.get("active", use: getActiveUsers)
    }
    
        /// GET /api/users - Récupére tous les utilisateurs
    func getAllUsers(req: Request) async throws -> [UserResponse] {
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("users").getDocuments()
            var users: [UserResponse] = []
            
            for document in snapshot.documents {
                if let user = try? document.data(as: User.self) {
                    var userWithId = user
                    userWithId.id = document.documentID
                    users.append(UserResponse(from: userWithId))
                }
            }
            
            return users
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des utilisateurs: \(error.localizedDescription)")
        }
    }
    
    /// POST /api/users - Crée un nouvel utilisateur
    func createUser(req: Request) async throws -> UserResponse {
        try User.validate(content: req)
        let userData = try req.content.decode(CreateUserRequest.self)
        
        let passwordHash = try req.password.hash(userData.password)
        
        let user = User(
            firstName: userData.firstName,
            lastName: userData.lastName,
            email: userData.email,
            passwordHash: passwordHash,
            phone: userData.phone,
            role: userData.role ?? "employee",
            department: userData.department,
            position: userData.position,
            weeklyHoursTarget: userData.weeklyHoursTarget ?? 35.0
        )
        
        let firestore = req.application.firestore
        
        do {
            // Vérifie que l'email n'existe pas déjà
            let existingUsers = try await firestore.collection("users")
                .whereField("email", isEqualTo: user.email)
                .getDocuments()
            
            if !existingUsers.documents.isEmpty {
                throw Abort(.conflict, reason: "Un utilisateur avec cet email existe déjà")
            }
            
            let docRef = try await firestore.collection("users").addDocument(data: [
                "firstName": user.firstName,
                "lastName": user.lastName,
                "email": user.email,
                "passwordHash": user.passwordHash,
                "phone": user.phone,
                "role": user.role,
                "department": user.department ?? "",
                "position": user.position ?? "",
                "hireDate": user.hireDate ?? Date(),
                "createdAt": user.createdAt,
                "updatedAt": user.updatedAt,
                "isActive": user.isActive,
                "weeklyHoursTarget": user.weeklyHoursTarget
            ])
            
            var createdUser = user
            createdUser.id = docRef.documentID
            
            return UserResponse(from: createdUser)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la création de l'utilisateur: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/users/:userID - Récupére un utilisateur spécifique
    func getUser(req: Request) async throws -> UserResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let document = try await firestore.collection("users").document(userID).getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Utilisateur non trouvé")
            }
            
            guard var user = try? document.data(as: User.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'utilisateur")
            }
            
            user.id = document.documentID
            return UserResponse(from: user)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération de l'utilisateur: \(error.localizedDescription)")
        }
    }
    
    /// PUT /api/users/:userID - Met à jour un utilisateur
    func updateUser(req: Request) async throws -> UserResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let updateData = try req.content.decode(UpdateUserRequest.self)
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("users").document(userID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Utilisateur non trouvé")
            }
            
            guard var existingUser = try? document.data(as: User.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'utilisateur")
            }
            
            // Mise à jour des champs modifiés
            var updateFields: [String: Any] = ["updatedAt": Date()]
            
            if let firstName = updateData.firstName {
                existingUser.firstName = firstName
                updateFields["firstName"] = firstName
            }
            if let lastName = updateData.lastName {
                existingUser.lastName = lastName
                updateFields["lastName"] = lastName
            }
            if let email = updateData.email {
                existingUser.email = email
                updateFields["email"] = email
            }
            if let phone = updateData.phone {
                existingUser.phone = phone
                updateFields["phone"] = phone
            }
            if let role = updateData.role {
                existingUser.role = role
                updateFields["role"] = role
            }
            if let department = updateData.department {
                existingUser.department = department
                updateFields["department"] = department
            }
            if let position = updateData.position {
                existingUser.position = position
                updateFields["position"] = position
            }
            if let weeklyHoursTarget = updateData.weeklyHoursTarget {
                existingUser.weeklyHoursTarget = weeklyHoursTarget
                updateFields["weeklyHoursTarget"] = weeklyHoursTarget
            }
            if let isActive = updateData.isActive {
                existingUser.isActive = isActive
                updateFields["isActive"] = isActive
            }
            
            try await docRef.updateData(updateFields)
            
            existingUser.id = userID
            existingUser.updatedAt = Date()
            
            return UserResponse(from: existingUser)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la mise à jour de l'utilisateur: \(error.localizedDescription)")
        }
    }
    
    /// DELETE /api/users/:userID - Supprime un utilisateur
    func deleteUser(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("users").document(userID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Utilisateur non trouvé")
            }
            
            // Marqueur inactif au lieu de supprimer
            try await docRef.updateData([
                "isActive": false,
                "updatedAt": Date()
            ])
            
            return .noContent
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la suppression de l'utilisateur: \(error.localizedDescription)")
        }
    }
    
    // Routes Spécialisées
    
    /// GET /api/users/:userID/profile - Profil complet de l'utilisateur
    func getUserProfile(req: Request) async throws -> UserProfileResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            // Récupére l'utilisateur
            let userDoc = try await firestore.collection("users").document(userID).getDocument()
            guard userDoc.exists, var user = try? userDoc.data(as: User.self) else {
                throw Abort(.notFound, reason: "Utilisateur non trouvé")
            }
            user.id = userDoc.documentID
            
            // Récupére les équipes
            let teamsSnapshot = try await firestore.collection("teams")
                .whereField("members", arrayContains: userID)
                .getDocuments()
            
            let teamCount = teamsSnapshot.documents.count
            
            // Récupére les entrées de temps récentes
            let timeEntriesSnapshot = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: userID)
                .order(by: "createdAt", descending: true)
                .limit(to: 5)
                .getDocuments()
            
            let recentTimeEntries = timeEntriesSnapshot.documents.count
            
            return UserProfileResponse(
                user: UserResponse(from: user),
                teamCount: teamCount,
                recentTimeEntries: recentTimeEntries,
                yearsOfService: user.yearsOfService ?? 0
            )
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération du profil: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/users/:userID/teams - Équipes de l'utilisateur
    func getUserTeams(req: Request) async throws -> [TeamSummary] {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("teams")
                .whereField("members", arrayContains: userID)
                .getDocuments()
            
            var teams: [TeamSummary] = []
            for document in snapshot.documents {
                if let team = try? document.data(as: Team.self) {
                    var teamWithId = team
                    teamWithId.id = document.documentID
                    teams.append(TeamSummary(from: teamWithId))
                }
            }
            
            return teams
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des équipes: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/users/:userID/timeentries - Entrées de temps de l'utilisateur
    func getUserTimeEntries(req: Request) async throws -> [TimeEntryResponse] {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let limit = req.query["limit"] ?? 10
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: userID)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            var timeEntries: [TimeEntryResponse] = []
            for document in snapshot.documents {
                if let timeEntry = try? document.data(as: TimeEntry.self) {
                    var timeEntryWithId = timeEntry
                    timeEntryWithId.id = document.documentID
                    timeEntries.append(TimeEntryResponse(from: timeEntryWithId))
                }
            }
            
            return timeEntries
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des entrées de temps: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/users/:userID/performance - Performance de l'utilisateur
    func getUserPerformance(req: Request) async throws -> [PerformanceResponse] {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("performances")
                .whereField("userId", isEqualTo: userID)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var performances: [PerformanceResponse] = []
            for document in snapshot.documents {
                if let performance = try? document.data(as: Performance.self) {
                    var performanceWithId = performance
                    performanceWithId.id = document.documentID
                    performances.append(PerformanceResponse(from: performanceWithId))
                }
            }
            
            return performances
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des performances: \(error.localizedDescription)")
        }
    }
    
    // Routes de recherches et filtres
    
    /// GET /api/users/search?q=terme - Recherche des utilisateurs
    func searchUsers(req: Request) async throws -> [UserResponse] {
        guard let searchTerm = req.query["q"] as String?, !searchTerm.isEmpty else {
            throw Abort(.badRequest, reason: "Terme de recherche manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            // Recherche par nom (limitation de Firestore - recherche exacte)
            let snapshot = try await firestore.collection("users")
                .whereField("firstName", isGreaterThanOrEqualTo: searchTerm)
                .whereField("firstName", isLessThan: searchTerm + "z")
                .getDocuments()
            
            var users: [UserResponse] = []
            for document in snapshot.documents {
                if let user = try? document.data(as: User.self) {
                    var userWithId = user
                    userWithId.id = document.documentID
                    users.append(UserResponse(from: userWithId))
                }
            }
            
            return users
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la recherche: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/users/by-role/:role - Utilisateurs par rôle
    func getUsersByRole(req: Request) async throws -> [UserResponse] {
        guard let role = req.parameters.get("role") else {
            throw Abort(.badRequest, reason: "Rôle manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("users")
                .whereField("role", isEqualTo: role)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            var users: [UserResponse] = []
            for document in snapshot.documents {
                if let user = try? document.data(as: User.self) {
                    var userWithId = user
                    userWithId.id = document.documentID
                    users.append(UserResponse(from: userWithId))
                }
            }
            
            return users
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des utilisateurs par rôle: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/users/active - Utilisateurs actifs
    func getActiveUsers(req: Request) async throws -> [UserResponse] {
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("users")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            var users: [UserResponse] = []
            for document in snapshot.documents {
                if let user = try? document.data(as: User.self) {
                    var userWithId = user
                    userWithId.id = document.documentID
                    users.append(UserResponse(from: userWithId))
                }
            }
            
            return users
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des utilisateurs actifs: \(error.localizedDescription)")
        }
    }
}

// Requêtes et Réponse des modèles

struct CreateUserRequest: Content, Validatable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let phone: String
    let role: String?
    let department: String?
    let position: String?
    let weeklyHoursTarget: Double?
    
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty && .count(2...50))
        validations.add("lastName", as: String.self, is: !.empty && .count(2...50))
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
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
    let id: String?
    let firstName: String
    let lastName: String
    let fullName: String
    let initials: String
    let email: String
    let phone: String
    let role: String
    let displayRole: String
    let department: String?
    let position: String?
    let hireDate: Date?
    let isActive: Bool
    let weeklyHoursTarget: Double
    let yearsOfService: Int?
    let isManager: Bool
    let isAdmin: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(from user: User) {
        self.id = user.id
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.fullName = user.fullName
        self.initials = user.initials
        self.email = user.email
        self.phone = user.phone
        self.role = user.role
        self.displayRole = user.displayRole
        self.department = user.department
        self.position = user.position
        self.hireDate = user.hireDate
        self.isActive = user.isActive
        self.weeklyHoursTarget = user.weeklyHoursTarget
        self.yearsOfService = user.yearsOfService
        self.isManager = user.isManager
        self.isAdmin = user.isAdmin
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }
}

struct UserProfileResponse: Content {
    let user: UserResponse
    let teamCount: Int
    let recentTimeEntries: Int
    let yearsOfService: Int
}

struct TeamSummary: Content {
    let id: String?
    let name: String
    let memberCount: Int
    let isManager: Bool
    
    init(from team: Team) {
        self.id = team.id
        self.name = team.name
        self.memberCount = team.memberCount
        self.isManager = false // À déterminer selon le contexte
    }
}

struct TimeEntryResponse: Content {
    let id: String?
    let userId: String
    let arrival: Date
    let departure: Date?
    let workDuration: String
    let calculatedHours: Double
    let isCurrentlyWorking: Bool
    let isOvertime: Bool
    let overtimeHours: Double
    let status: String
    let notes: String?
    let workPeriod: String
    
    init(from timeEntry: TimeEntry) {
        self.id = timeEntry.id
        self.userId = timeEntry.userId
        self.arrival = timeEntry.arrival
        self.departure = timeEntry.departure
        self.workDuration = timeEntry.workDuration
        self.calculatedHours = timeEntry.calculatedHours
        self.isCurrentlyWorking = timeEntry.isCurrentlyWorking
        self.isOvertime = timeEntry.isOvertime
        self.overtimeHours = timeEntry.overtimeHours
        self.status = timeEntry.status
        self.notes = timeEntry.notes
        self.workPeriod = timeEntry.workPeriod
    }
}

struct PerformanceResponse: Content {
    let id: String?
    let userId: String
    let period: String
    let index: Double
    let performanceLevel: String
    let isExcellent: Bool
    let createdAt: Date
    
    init(from performance: Performance) {
        self.id = performance.id
        self.userId = performance.userId
        self.period = performance.period
        self.index = performance.index
        self.performanceLevel = performance.performanceLevel
        self.isExcellent = performance.isExcellent
        self.createdAt = performance.createdAt
    }
}

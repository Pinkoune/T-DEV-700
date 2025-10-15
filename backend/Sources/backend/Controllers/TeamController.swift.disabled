import Vapor
import FirebaseFirestore

struct TeamController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let teams = routes.grouped("api", "teams")
        
        // Routes protégées par JWT
        let protected = teams.grouped(JWTAuthMiddleware())
        
        // Application de la protection à toutes les routes
        protected.get(use: getAllTeams)
        protected.post(use: createTeam)
        protected.group(":teamID") { team in
            team.get(use: getTeam)
            team.put(use: updateTeam)
            team.delete(use: deleteTeam)
            
            // Gestion des membres
            team.post("members", ":userID", use: addMember)
            team.delete("members", ":userID", use: removeMember)
            team.get("members", use: getTeamMembers)
            
            // Statistiques de l'équipe
            team.get("stats", use: getTeamStats)
            team.get("performance", use: getTeamPerformance)
        }
        
        // Routes de recherche et filtrage
        protected.get("search", use: searchTeams)
        protected.get("active", use: getActiveTeams)
        protected.get("by-manager", ":managerID", use: getTeamsByManager)
    }
    
    
    // Opérations CRUD
    
    /// GET /api/teams - Récupére toutes les équipes
    func getAllTeams(req: Request) async throws -> [TeamResponse] {
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("teams").getDocuments()
            var teams: [TeamResponse] = []
            
            for document in snapshot.documents {
                if let team = try? document.data(as: Team.self) {
                    var teamWithId = team
                    teamWithId.id = document.documentID
                    teams.append(TeamResponse(from: teamWithId))
                }
            }
            
            return teams
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des équipes: \(error.localizedDescription)")
        }
    }
    
    /// POST /api/teams - Crée une nouvelle équipe
    func createTeam(req: Request) async throws -> TeamResponse {
        try Team.validate(content: req)
        let teamData = try req.content.decode(CreateTeamRequest.self)
        
        let team = Team(
            name: teamData.name,
            description: teamData.description,
            managerId: teamData.managerId,
            color: teamData.color ?? "#007AFF"
        )
        
        let firestore = req.application.firestore
        
        do {
            // Vérifie que le manager existe
            let managerDoc = try await firestore.collection("users").document(teamData.managerId).getDocument()
            guard managerDoc.exists else {
                throw Abort(.badRequest, reason: "Manager non trouvé")
            }
            
            // Vérifie qu'une équipe avec ce nom n'existe pas déjà
            let existingTeams = try await firestore.collection("teams")
                .whereField("name", isEqualTo: team.name)
                .getDocuments()
            
            if !existingTeams.documents.isEmpty {
                throw Abort(.conflict, reason: "Une équipe avec ce nom existe déjà")
            }
            
            let docRef = try await firestore.collection("teams").addDocument(data: [
                "name": team.name,
                "description": team.description,
                "members": team.members,
                "managerId": team.managerId,
                "color": team.color,
                "createdAt": team.createdAt,
                "updatedAt": team.updatedAt,
                "isActive": team.isActive
            ])
            
            var createdTeam = team
            createdTeam.id = docRef.documentID
            
            return TeamResponse(from: createdTeam)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la création de l'équipe: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/teams/:teamID - Récupére une équipe spécifique
    func getTeam(req: Request) async throws -> TeamDetailResponse {
        guard let teamID = req.parameters.get("teamID") else {
            throw Abort(.badRequest, reason: "ID équipe manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let document = try await firestore.collection("teams").document(teamID).getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            guard var team = try? document.data(as: Team.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'équipe")
            }
            
            team.id = document.documentID
            
            // Récupére les détails des membres
            var memberDetails: [UserResponse] = []
            for memberID in team.members {
                let memberDoc = try await firestore.collection("users").document(memberID).getDocument()
                if memberDoc.exists, let user = try? memberDoc.data(as: User.self) {
                    var userWithId = user
                    userWithId.id = memberDoc.documentID
                    memberDetails.append(UserResponse(from: userWithId))
                }
            }
            
            // Récupére les détails du manager
            let managerDoc = try await firestore.collection("users").document(team.managerId).getDocument()
            var manager: UserResponse?
            if managerDoc.exists, let managerUser = try? managerDoc.data(as: User.self) {
                var managerWithId = managerUser
                managerWithId.id = managerDoc.documentID
                manager = UserResponse(from: managerWithId)
            }
            
            return TeamDetailResponse(
                team: TeamResponse(from: team),
                members: memberDetails,
                manager: manager
            )
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération de l'équipe: \(error.localizedDescription)")
        }
    }
    
    /// PUT /api/teams/:teamID - Met à jour une équipe
    func updateTeam(req: Request) async throws -> TeamResponse {
        guard let teamID = req.parameters.get("teamID") else {
            throw Abort(.badRequest, reason: "ID équipe manquant")
        }
        
        let updateData = try req.content.decode(UpdateTeamRequest.self)
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("teams").document(teamID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            guard var existingTeam = try? document.data(as: Team.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'équipe")
            }
            
            // Mise à jour des champs modifiés
            var updateFields: [String: Any] = ["updatedAt": Date()]
            
            if let name = updateData.name {
                existingTeam.name = name
                updateFields["name"] = name
            }
            if let description = updateData.description {
                existingTeam.description = description
                updateFields["description"] = description
            }
            if let managerId = updateData.managerId {
                // Vérifie que le nouveau manager existe
                let managerDoc = try await firestore.collection("users").document(managerId).getDocument()
                guard managerDoc.exists else {
                    throw Abort(.badRequest, reason: "Nouveau manager non trouvé")
                }
                existingTeam.managerId = managerId
                updateFields["managerId"] = managerId
            }
            if let color = updateData.color {
                existingTeam.color = color
                updateFields["color"] = color
            }
            if let isActive = updateData.isActive {
                existingTeam.isActive = isActive
                updateFields["isActive"] = isActive
            }
            
            try await docRef.updateData(updateFields)
            
            existingTeam.id = teamID
            existingTeam.updatedAt = Date()
            
            return TeamResponse(from: existingTeam)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la mise à jour de l'équipe: \(error.localizedDescription)")
        }
    }
    
    /// DELETE /api/teams/:teamID - Supprime une équipe
    func deleteTeam(req: Request) async throws -> HTTPStatus {
        guard let teamID = req.parameters.get("teamID") else {
            throw Abort(.badRequest, reason: "ID équipe manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("teams").document(teamID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            // Marqueur inactive
            try await docRef.updateData([
                "isActive": false,
                "updatedAt": Date()
            ])
            
            return .noContent
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la suppression de l'équipe: \(error.localizedDescription)")
        }
    }
    
    // Management des membres
    
    /// POST /api/teams/:teamID/members/:userID - Ajoute un membre à l'équipe
    func addMember(req: Request) async throws -> HTTPStatus {
        guard let teamID = req.parameters.get("teamID"),
              let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID équipe ou utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            // Vérifie que l'utilisateur existe
            let userDoc = try await firestore.collection("users").document(userID).getDocument()
            guard userDoc.exists else {
                throw Abort(.notFound, reason: "Utilisateur non trouvé")
            }
            
            // Vérifie que l'équipe existe
            let teamDoc = try await firestore.collection("teams").document(teamID).getDocument()
            guard teamDoc.exists else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            guard let team = try? teamDoc.data(as: Team.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'équipe")
            }
            
            // Vérifie que l'utilisateur n'est pas déjà membre
            if team.isMember(userID) {
                throw Abort(.conflict, reason: "L'utilisateur est déjà membre de cette équipe")
            }
            
            // Ajoute le membre
            var updatedMembers = team.members
            updatedMembers.append(userID)
            
            try await firestore.collection("teams").document(teamID).updateData([
                "members": updatedMembers,
                "updatedAt": Date()
            ])
            
            return .created
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de l'ajout du membre: \(error.localizedDescription)")
        }
    }
    
    /// DELETE /api/teams/:teamID/members/:userID - Retire un membre de l'équipe
    func removeMember(req: Request) async throws -> HTTPStatus {
        guard let teamID = req.parameters.get("teamID"),
              let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID équipe ou utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let teamDoc = try await firestore.collection("teams").document(teamID).getDocument()
            guard teamDoc.exists else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            guard let team = try? teamDoc.data(as: Team.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'équipe")
            }
            
            // Vérifie que l'utilisateur est membre
            if !team.isMember(userID) {
                throw Abort(.notFound, reason: "L'utilisateur n'est pas membre de cette équipe")
            }
            
            // Pour ne pas permettre de retirer le manager
            if team.isManager(userID) {
                throw Abort(.badRequest, reason: "Impossible de retirer le manager de l'équipe")
            }
            
            // Retire le membre
            let updatedMembers = team.members.filter { $0 != userID }
            
            try await firestore.collection("teams").document(teamID).updateData([
                "members": updatedMembers,
                "updatedAt": Date()
            ])
            
            return .noContent
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors du retrait du membre: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/teams/:teamID/members - Récupére les membres de l'équipe
    func getTeamMembers(req: Request) async throws -> [UserResponse] {
        guard let teamID = req.parameters.get("teamID") else {
            throw Abort(.badRequest, reason: "ID équipe manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let teamDoc = try await firestore.collection("teams").document(teamID).getDocument()
            guard teamDoc.exists else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            guard let team = try? teamDoc.data(as: Team.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'équipe")
            }
            
            var members: [UserResponse] = []
            for memberID in team.members {
                let memberDoc = try await firestore.collection("users").document(memberID).getDocument()
                if memberDoc.exists, let user = try? memberDoc.data(as: User.self) {
                    var userWithId = user
                    userWithId.id = memberDoc.documentID
                    members.append(UserResponse(from: userWithId))
                }
            }
            
            return members
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des membres: \(error.localizedDescription)")
        }
    }
    
    // Statistiques et Performances
    
    /// GET /api/teams/:teamID/stats - Statistiques de l'équipe
    func getTeamStats(req: Request) async throws -> TeamStatsResponse {
        guard let teamID = req.parameters.get("teamID") else {
            throw Abort(.badRequest, reason: "ID équipe manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let teamDoc = try await firestore.collection("teams").document(teamID).getDocument()
            guard teamDoc.exists, let team = try? teamDoc.data(as: Team.self) else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            // Calcule les statistiques
            let totalMembers = team.memberCount
            
            // Compte les entrées de temps actives
            var activeTimeEntries = 0
            for memberID in team.members {
                let timeEntriesSnapshot = try await firestore.collection("timeEntries")
                    .whereField("userId", isEqualTo: memberID)
                    .whereField("status", isEqualTo: "active")
                    .getDocuments()
                activeTimeEntries += timeEntriesSnapshot.documents.count
            }
            
            // Calcule la performance moyenne de l'équipe
            var totalPerformance = 0.0
            var performanceCount = 0
            
            for memberID in team.members {
                let performanceSnapshot = try await firestore.collection("performances")
                    .whereField("userId", isEqualTo: memberID)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 1)
                    .getDocuments()
                
                if let latestPerformance = performanceSnapshot.documents.first,
                   let performance = try? latestPerformance.data(as: Performance.self) {
                    totalPerformance += performance.index
                    performanceCount += 1
                }
            }
            
            let averagePerformance = performanceCount > 0 ? totalPerformance / Double(performanceCount) : 0.0
            
            return TeamStatsResponse(
                teamId: teamID,
                totalMembers: totalMembers,
                activeTimeEntries: activeTimeEntries,
                averagePerformance: averagePerformance,
                teamSize: team.teamSize,
                isLargeTeam: team.isLargeTeam
            )
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors du calcul des statistiques: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/teams/:teamID/performance - Performance de l'équipe
    func getTeamPerformance(req: Request) async throws -> [TeamMemberPerformance] {
        guard let teamID = req.parameters.get("teamID") else {
            throw Abort(.badRequest, reason: "ID équipe manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let teamDoc = try await firestore.collection("teams").document(teamID).getDocument()
            guard teamDoc.exists, let team = try? teamDoc.data(as: Team.self) else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            var memberPerformances: [TeamMemberPerformance] = []
            
            for memberID in team.members {
                // Récupére l'utilisateur
                let userDoc = try await firestore.collection("users").document(memberID).getDocument()
                guard userDoc.exists, let user = try? userDoc.data(as: User.self) else {
                    continue
                }
                
                // Récupére la performance la plus récente
                let performanceSnapshot = try await firestore.collection("performances")
                    .whereField("userId", isEqualTo: memberID)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 1)
                    .getDocuments()
                
                var latestPerformance: Performance?
                if let performanceDoc = performanceSnapshot.documents.first {
                    latestPerformance = try? performanceDoc.data(as: Performance.self)
                }
                
                memberPerformances.append(TeamMemberPerformance(
                    userId: memberID,
                    userName: user.fullName,
                    isManager: team.isManager(memberID),
                    latestPerformance: latestPerformance?.index,
                    performanceLevel: latestPerformance?.performanceLevel ?? "Non évalué"
                ))
            }
            
            return memberPerformances
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des performances: \(error.localizedDescription)")
        }
    }
    
    // Routes pour la recherche et filtres
    
    /// GET /api/teams/search?q=terme - Recherche des équipes
    func searchTeams(req: Request) async throws -> [TeamResponse] {
        guard let searchTerm = req.query["q"] as String?, !searchTerm.isEmpty else {
            throw Abort(.badRequest, reason: "Terme de recherche manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("teams")
                .whereField("name", isGreaterThanOrEqualTo: searchTerm)
                .whereField("name", isLessThan: searchTerm + "z")
                .getDocuments()
            
            var teams: [TeamResponse] = []
            for document in snapshot.documents {
                if let team = try? document.data(as: Team.self) {
                    var teamWithId = team
                    teamWithId.id = document.documentID
                    teams.append(TeamResponse(from: teamWithId))
                }
            }
            
            return teams
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la recherche: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/teams/active - Équipes actives
    func getActiveTeams(req: Request) async throws -> [TeamResponse] {
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("teams")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            var teams: [TeamResponse] = []
            for document in snapshot.documents {
                if let team = try? document.data(as: Team.self) {
                    var teamWithId = team
                    teamWithId.id = document.documentID
                    teams.append(TeamResponse(from: teamWithId))
                }
            }
            
            return teams
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des équipes actives: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/teams/by-manager/:managerID - Équipes par manager
    func getTeamsByManager(req: Request) async throws -> [TeamResponse] {
        guard let managerID = req.parameters.get("managerID") else {
            throw Abort(.badRequest, reason: "ID manager manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("teams")
                .whereField("managerId", isEqualTo: managerID)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            var teams: [TeamResponse] = []
            for document in snapshot.documents {
                if let team = try? document.data(as: Team.self) {
                    var teamWithId = team
                    teamWithId.id = document.documentID
                    teams.append(TeamResponse(from: teamWithId))
                }
            }
            
            return teams
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des équipes du manager: \(error.localizedDescription)")
        }
    }

// Requêtes et réponses pour les Models

struct CreateTeamRequest: Content, Validatable {
    let name: String
    let description: String
    let managerId: String
    let color: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(2...50))
        validations.add("description", as: String.self, is: .count(...500))
        validations.add("managerId", as: String.self, is: !.empty)
    }
}

struct UpdateTeamRequest: Content {
    let name: String?
    let description: String?
    let managerId: String?
    let color: String?
    let isActive: Bool?
}

struct TeamResponse: Content {
    let id: String?
    let name: String
    let description: String
    let memberCount: Int
    let managerId: String
    let color: String
    let teamSize: String
    let isLargeTeam: Bool
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(from team: Team) {
        self.id = team.id
        self.name = team.name
        self.description = team.description
        self.memberCount = team.memberCount
        self.managerId = team.managerId
        self.color = team.color
        self.teamSize = team.teamSize
        self.isLargeTeam = team.isLargeTeam
        self.isActive = team.isActive
        self.createdAt = team.createdAt
        self.updatedAt = team.updatedAt
    }
}

struct TeamDetailResponse: Content {
    let team: TeamResponse
    let members: [UserResponse]
    let manager: UserResponse?
}

struct TeamStatsResponse: Content {
    let teamId: String
    let totalMembers: Int
    let activeTimeEntries: Int
    let averagePerformance: Double
    let teamSize: String
    let isLargeTeam: Bool
}

struct TeamMemberPerformance: Content {
    let userId: String
    let userName: String
    let isManager: Bool
    let latestPerformance: Double?
    let performanceLevel: String
}
}

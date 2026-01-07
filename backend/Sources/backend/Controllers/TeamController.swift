import Vapor
import Fluent

struct TeamController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let teams = routes.grouped("teams")

        let protected = teams.grouped(JWTAuthMiddleware())
        
        protected.get(use: getAllTeams)
        protected.get("search", use: searchTeams)
        protected.get("active", use: getActiveTeams)

        // Routes accessibles par les managers uniquement
        let manager = protected.grouped(ManagerMiddleware())
        manager.post(use: createTeam)
        manager.get("by-manager", ":managerID", use: getTeamsByManager)

        manager.group(":teamID") { team in
            team.get(use: getTeam)
            team.put(use: updateTeam)
            team.delete(use: deleteTeam)
            
            team.get("members", use: getTeamMembers)
            team.post("members", ":userID", use: addMember)
            team.delete("members", ":userID", use: removeMember)

            team.get("members", ":userID", "stats", use: getMemberStats)
            team.get("stats", use: getTeamStats)
            team.get("performance", use: getTeamPerformance)
        }
    }

    
    /// GET /teams - Récupère toutes les équipes
    func getAllTeams(req: Request) async throws -> [TeamResponse] {
        let teams = try await Team.query(on: req.db)
            .all()
        
        return teams.map { TeamResponse(from: $0) }
    }
    
    /// GET /teams/:teamID/members/:userID/stats - Stats détaillées d'un membre
    func getMemberStats(req: Request) async throws -> TeamMemberStatsResponse {
        guard let teamID = req.parameters.get("teamID", as: UUID.self),
              let userID = req.parameters.get("userID", as: UUID.self) else {
            req.logger.error("[getMemberStats] Invalid IDs")
            throw Abort(.badRequest, reason: "ID invalide")
        }
        
        guard let team = try await Team.find(teamID, on: req.db) else {
            req.logger.error("[getMemberStats] Team not found: \(teamID)")
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }
        
        req.logger.info("[getMemberStats] Checking membership for user \(userID) in team \(teamID)")
        if !team.isMember(userID) && team.managerId != userID {
             req.logger.error("[getMemberStats] User \(userID) is not a member of team \(teamID). Members: \(team.members)")
             throw Abort(.notFound, reason: "Membre non trouvé dans cette équipe")
        }
        
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let recentEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt >= sevenDaysAgo)
            .all()
        
        let totalHours = recentEntries.reduce(0.0) { $0 + ($1.hoursWorked ?? 0.0) }
        
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        guard let user = try await User.find(userID, on: req.db) else {
             req.logger.error("[getMemberStats] User profile not found: \(userID)")
             throw Abort(.notFound)
        }
        
        let monthEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt >= startOfMonth)
            .all()
        
        var latenessCount = 0
        for entry in monthEntries {
            if entry.isLate(expectedArrivalTime: user.expectedArrivalTime) {
                latenessCount += 1
            }
        }
        
        let randomMock = Double(abs(userID.hashValue) % 20) + 80.0
        
        var dailyStats: [DailyStats] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hoursForDay = recentEntries.filter {
                guard let createdAt = $0.createdAt else { return false }
                return createdAt >= dayStart && createdAt < dayEnd
            }.reduce(0.0) { $0 + ($1.hoursWorked ?? 0.0) }
            
            dailyStats.insert(DailyStats(date: dateFormatter.string(from: date), hours: hoursForDay), at: 0)
        }
        
        return TeamMemberStatsResponse(
            userId: userID.uuidString,
            averageWeeklyHours: totalHours,
            latenessCount: latenessCount,
            taskCompletionRate: randomMock,
            lastSevenDays: dailyStats
        )
    }

    /// GET /teams/:teamID - Récupère une équipe spécifique avec détails
    func getTeam(req: Request) async throws -> TeamDetailResponse {
        guard let teamID = req.parameters.get("teamID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe invalide")
        }

        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }

        var memberDetails: [UserResponse] = []
        for memberID in team.members {
            if let user = try await User.find(memberID, on: req.db) {
                memberDetails.append(UserResponse(from: user))
            }
        }

        let manager = try await User.find(team.managerId, on: req.db)

        return TeamDetailResponse(
            team: TeamResponse(from: team),
            members: memberDetails,
            manager: manager != nil ? UserResponse(from: manager!) : nil
        )
    }
    
    /// POST /teams - Crée une nouvelle équipe
    func createTeam(req: Request) async throws -> TeamResponse {
        try CreateTeamRequest.validate(content: req)
        let teamData = try req.content.decode(CreateTeamRequest.self)
        
        guard let _ = try await User.find(teamData.managerId, on: req.db) else {
            throw Abort(.badRequest, reason: "Manager non trouvé")
        }

        let existingTeam = try await Team.query(on: req.db)
            .filter(\.$name == teamData.name)
            .first()

        if existingTeam != nil {
            throw Abort(.conflict, reason: "Une équipe avec ce nom existe déjà")
        }

        let team = Team(
            name: teamData.name,
            description: teamData.description,
            managerId: teamData.managerId,
            color: teamData.color ?? "#007AFF"
        )
        
        try await team.save(on: req.db)
        
        return TeamResponse(from: team)
    }
    
    /// PUT /teams/:teamID - Mise à jour d'une équipe(nom, description, managerId, membres)
    func updateTeam(req: Request) async throws -> TeamResponse {
        guard let teamID = req.parameters.get("teamID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe invalide")
        }
        
        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }
        
        let updateData = try req.content.decode(UpdateTeamRequest.self)
        
        if let name = updateData.name {
            team.name = name
        }
        if let description = updateData.description {
            team.description = description
        }
        if let managerId = updateData.managerId {
            guard let _ = try await User.find(managerId, on: req.db) else {
                throw Abort(.badRequest, reason: "Nouveau manager non trouvé")
            }
            team.managerId = managerId
        }
        if let color = updateData.color {
            team.color = color
        }
        if let isActive = updateData.isActive {
            team.isActive = isActive
        }

        try await team.save(on: req.db)

        return TeamResponse(from: team)
    }
    
    /// DELETE /teams/:teamID - Désactivation d'une équipe sans la supprimer
    func deleteTeam(req: Request) async throws -> HTTPStatus {
        guard let teamID = req.parameters.get("teamID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe invalide")
        }
        
        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }

        // Soft delete : marquer comme inactive
        team.isActive = false
        try await team.save(on: req.db)

        return .noContent
    }

    
    /// POST /teams/:teamID/members/:userID - Ajoute un membre à l'équipe
    func addMember(req: Request) async throws -> HTTPStatus {
        guard let teamID = req.parameters.get("teamID", as: UUID.self),
              let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe ou utilisateur invalide")
        }
        
        guard let _ = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }

        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }

        if team.isMember(userID) {
            throw Abort(.conflict, reason: "L'utilisateur est déjà membre de cette équipe")
        }

        team.members.append(userID)
        try await team.save(on: req.db)

        return .created
    }
    
    /// DELETE /teams/:teamID/members/:userID - Suppression d'un membre de l'équipe
    func removeMember(req: Request) async throws -> HTTPStatus {
        guard let teamID = req.parameters.get("teamID", as: UUID.self),
              let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe ou utilisateur invalide")
        }
        
        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }

        if !team.isMember(userID) {
            throw Abort(.notFound, reason: "L'utilisateur n'est pas membre de cette équipe")
        }

        if team.isManager(userID) {
            throw Abort(.badRequest, reason: "Impossible de retirer le manager de l'équipe")
        }

        team.members.removeAll { $0 == userID }
        try await team.save(on: req.db)

        return .noContent
    }
    
    /// GET /teams/:teamID/members - Récupèration des membres de l'équipe
    func getTeamMembers(req: Request) async throws -> [UserResponse] {
        guard let teamID = req.parameters.get("teamID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe invalide")
        }
        
        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }

        var members: [UserResponse] = []
        for memberID in team.members {
            if let user = try await User.find(memberID, on: req.db) {
                members.append(UserResponse(from: user))
            }
        }

        return members
    }

    /// GET /teams/:teamID/stats - Statistiques de l'équipe en fonction de la période et des performances.
    func getTeamStats(req: Request) async throws -> TeamStatsResponse {
        guard let teamID = req.parameters.get("teamID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe invalide")
        }
        
        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }

        // Compter les entrées de temps actives
        var activeTimeEntries = 0
        for memberID in team.members {
            let count = try await TimeEntry.query(on: req.db)
                .filter(\.$user.$id == memberID)
                .filter(\.$status == "active")
                .count()
            activeTimeEntries += count
        }

        // Calculer la performance moyenne de l'équipe
        var totalPerformance = 0.0
        var performanceCount = 0

        for memberID in team.members {
            if let latestPerformance = try await Performance.query(on: req.db)
                .filter(\.$user.$id == memberID)
                .sort(\.$createdAt, .descending)
                .first() {
                totalPerformance += latestPerformance.index
                performanceCount += 1
            }
        }

        let averagePerformance = performanceCount > 0 ? totalPerformance / Double(performanceCount) : 0.0

        // Calculer le lateness rate de l'équipe (ce mois)
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        var totalEntries = 0
        var totalLateEntries = 0
        var totalLateMinutes = 0

        for memberID in team.members {
            guard let user = try await User.find(memberID, on: req.db) else { continue }
            
            let entries = try await TimeEntry.query(on: req.db)
                .filter(\.$user.$id == memberID)
                .filter(\.$createdAt >= startOfMonth)
                .filter(\.$status == "completed")
                .all()

            totalEntries += entries.count

            for entry in entries {
                if entry.isLate(expectedArrivalTime: user.expectedArrivalTime) {
                    totalLateEntries += 1
                    totalLateMinutes += entry.lateMinutes(expectedArrivalTime: user.expectedArrivalTime)
                }
            }
        }

        let latenessRate = totalEntries > 0 ? (Double(totalLateEntries) / Double(totalEntries)) * 100 : 0.0
        let averageLateMinutes = totalLateEntries > 0 ? Double(totalLateMinutes) / Double(totalLateEntries) : 0.0

        return TeamStatsResponse(
            teamId: teamID.uuidString,
            totalMembers: team.memberCount,
            activeTimeEntries: activeTimeEntries,
            averagePerformance: averagePerformance,
            teamSize: team.teamSize,
            isLargeTeam: team.isLargeTeam,
            latenessRate: latenessRate,
            totalLateEntries: totalLateEntries,
            averageLateMinutes: averageLateMinutes
        )
    }
    
    /// GET /teams/:teamID/performance - Performance de l'équipe
    func getTeamPerformance(req: Request) async throws -> [TeamMemberPerformance] {
        guard let teamID = req.parameters.get("teamID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe invalide")
        }
        
        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }

        var memberPerformances: [TeamMemberPerformance] = []

        for memberID in team.members {
            // Récupérer l'utilisateur
            guard let user = try await User.find(memberID, on: req.db) else {
                continue
            }

            // Récupérer la performance la plus récente
            let latestPerformance = try await Performance.query(on: req.db)
                .filter(\.$user.$id == memberID)
                .sort(\.$createdAt, .descending)
                .first()

            memberPerformances.append(TeamMemberPerformance(
                userId: memberID.uuidString,
                userName: user.fullName,
                isManager: team.isManager(memberID),
                latestPerformance: latestPerformance?.index,
                performanceLevel: latestPerformance?.performanceLevel ?? "Non évalué"
            ))
        }

        return memberPerformances
    }
    
    // MARK: - Search & Filters
    
    /// GET /teams/search?q=terme - Recherche des équipes
    func searchTeams(req: Request) async throws -> [TeamResponse] {
        guard let searchTerm = req.query[String.self, at: "q"], !searchTerm.isEmpty else {
            throw Abort(.badRequest, reason: "Terme de recherche manquant")
        }
        
        let searchPattern = "%\(searchTerm.lowercased())%"
        
        let teams = try await Team.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$name, .custom("ILIKE"), searchPattern)
                group.filter(\.$description, .custom("ILIKE"), searchPattern)
            }
            .all()

        return teams.map { TeamResponse(from: $0) }
    }
    
    /// GET /teams/active - Équipes actives
    func getActiveTeams(req: Request) async throws -> [TeamResponse] {
        let teams = try await Team.query(on: req.db)
            .filter(\.$isActive == true)
            .all()
        
        return teams.map { TeamResponse(from: $0) }
    }
    
    /// GET /teams/by-manager/:managerID - Équipes par manager
    func getTeamsByManager(req: Request) async throws -> [TeamResponse] {
        guard let managerID = req.parameters.get("managerID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID manager invalide")
        }
        
        let teams = try await Team.query(on: req.db)
            .filter(\.$managerId == managerID)
            .filter(\.$isActive == true)
            .all()
        
        return teams.map { TeamResponse(from: $0) }
    }
}


struct CreateTeamRequest: Content, Validatable {
    let name: String
    let description: String
    let managerId: UUID
    let color: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(2...50))
        validations.add("description", as: String.self, is: .count(...500))
    }
}

struct UpdateTeamRequest: Content {
    let name: String?
    let description: String?
    let managerId: UUID?
    let color: String?
    let isActive: Bool?
}

struct TeamResponse: Content {
    let id: UUID?
    let name: String
    let description: String
    let memberCount: Int
    let managerId: UUID
    let color: String
    let teamSize: String
    let isLargeTeam: Bool
    let isActive: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
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
    let latenessRate: Double
    let totalLateEntries: Int
    let averageLateMinutes: Double
}

struct TeamMemberPerformance: Content {
    let userId: String
    let userName: String
    let isManager: Bool
    let latestPerformance: Double?
    let performanceLevel: String
}

struct TeamMemberStatsResponse: Content {
    let userId: String
    let averageWeeklyHours: Double
    let latenessCount: Int
    let taskCompletionRate: Double
    let lastSevenDays: [DailyStats]
}

struct DailyStats: Content {
    let date: String
    let hours: Double
}

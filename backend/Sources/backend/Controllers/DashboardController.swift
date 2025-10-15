import Vapor
import Fluent

struct DashboardController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let dashboard = routes.grouped("dashboard")
        
        // Routes protégées par JWT
        let protected = dashboard.grouped(JWTAuthMiddleware())
        
        // Dashboard utilisateur (accessible par tous les authentifiés)
        protected.get("user", ":userID", use: getUserDashboard)
        
        // Routes managers seulement
        let manager = protected.grouped(ManagerMiddleware())
        manager.get("team", ":teamID", "hours", use: getTeamHoursStats)
        manager.get("employee", ":userID", "hours", use: getEmployeeHoursStats)
    }
    
    // Dashboard utilisateur
    func getUserDashboard(req: Request) async throws -> UserDashboardResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let monthTimeEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt >= startOfMonth)
            .filter(\.$status == "completed")
            .all()
        
        let weekTimeEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt >= startOfWeek)
            .filter(\.$status == "completed")
            .all()
        
        var totalHoursMonth = 0.0
        for entry in monthTimeEntries {
            if let hours = entry.hoursWorked {
                totalHoursMonth = totalHoursMonth + hours
            }
        }
        
        var totalHoursWeek = 0.0
        for entry in weekTimeEntries {
            if let hours = entry.hoursWorked {
                totalHoursWeek = totalHoursWeek + hours
            }
        }
        
        var daysMonth: [Date] = []
        for entry in monthTimeEntries {
            let day = calendar.startOfDay(for: entry.arrival)
            if !daysMonth.contains(day) {
                daysMonth.append(day)
            }
        }
        let daysWorkedMonth = daysMonth.count
        
        var daysWeek: [Date] = []
        for entry in weekTimeEntries {
            let day = calendar.startOfDay(for: entry.arrival)
            if !daysWeek.contains(day) {
                daysWeek.append(day)
            }
        }
        let daysWorkedWeek = daysWeek.count
        
        var averageHoursPerDayMonth = 0.0
        if daysWorkedMonth > 0 {
            averageHoursPerDayMonth = totalHoursMonth / Double(daysWorkedMonth)
        }
        
        var averageHoursPerDayWeek = 0.0
        if daysWorkedWeek > 0 {
            averageHoursPerDayWeek = totalHoursWeek / Double(daysWorkedWeek)
        }
        
        let activeEntry = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$status == "active")
            .first()
        
        let latestPerformance = try await Performance.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .first()
        
        let allTeams = try await Team.query(on: req.db).all()
        var userTeams: [Team] = []
        for team in allTeams {
            if team.isMember(userID) {
                userTeams.append(team)
            }
        }
        
        var overtimeHours = 0.0
        for entry in monthTimeEntries {
            if entry.isOvertime {
                overtimeHours = overtimeHours + entry.overtimeHours
            }
        }
        
        var status = "offline"
        if activeEntry != nil {
            status = "working"
        }
        
        var activeEntryResponse: TimeEntryResponse? = nil
        if let active = activeEntry {
            activeEntryResponse = TimeEntryResponse(from: active)
        }
        
        var performanceResponse: PerformanceResponse? = nil
        if let perf = latestPerformance {
            performanceResponse = PerformanceResponse(from: perf)
        }
        
        var teamsResponse: [DashboardTeamResponse] = []
        for team in userTeams {
            teamsResponse.append(DashboardTeamResponse(from: team))
        }
        
        let stats = DashboardStats(
            totalHoursThisMonth: totalHoursMonth,
            totalHoursThisWeek: totalHoursWeek,
            averageHoursPerDayMonth: averageHoursPerDayMonth,
            averageHoursPerDayWeek: averageHoursPerDayWeek,
            daysWorkedThisMonth: daysWorkedMonth,
            daysWorkedThisWeek: daysWorkedWeek,
            overtimeHours: overtimeHours
        )
        
        return UserDashboardResponse(
            user: UserResponse(from: user),
            currentStatus: status,
            activeEntry: activeEntryResponse,
            stats: stats,
            performance: performanceResponse,
            teams: teamsResponse,
            weeklyTarget: user.weeklyHoursTarget
        )
    }
    
    // Statistiques d'heures de l'équipe pour les managers
    func getTeamHoursStats(req: Request) async throws -> TeamHoursStatsResponse {
        guard let teamID = req.parameters.get("teamID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID équipe invalide")
        }
        
        guard let team = try await Team.find(teamID, on: req.db) else {
            throw Abort(.notFound, reason: "Équipe non trouvée")
        }
        
        // Récupérer la période depuis les query params (week ou month)
        let period = req.query[String.self, at: "period"] ?? "month"
        
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case "week":
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case "month":
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        default:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        }
        
        // Récupérer toutes les entrées de temps des membres de l'équipe
        var memberStats: [MemberHoursStats] = []
        var totalTeamHours = 0.0
        var totalDaysWorked = 0
        
        for memberID in team.members {
            guard let member = try await User.find(memberID, on: req.db) else {
                continue
            }
            
            let timeEntries = try await TimeEntry.query(on: req.db)
                .filter(\.$user.$id == memberID)
                .filter(\.$createdAt >= startDate)
                .filter(\.$status == "completed")
                .all()
            
            var totalHours = 0.0
            for entry in timeEntries {
                if let hours = entry.hoursWorked {
                    totalHours = totalHours + hours
                }
            }
            
            var days: [Date] = []
            for entry in timeEntries {
                let day = calendar.startOfDay(for: entry.arrival)
                if !days.contains(day) {
                    days.append(day)
                }
            }
            let daysWorked = days.count
            
            var averageHoursPerDay = 0.0
            if daysWorked > 0 {
                averageHoursPerDay = totalHours / Double(daysWorked)
            }
            
            totalTeamHours = totalTeamHours + totalHours
            totalDaysWorked = totalDaysWorked + daysWorked
            
            memberStats.append(MemberHoursStats(
                userId: memberID,
                userName: member.fullName,
                totalHours: totalHours,
                daysWorked: daysWorked,
                averageHoursPerDay: averageHoursPerDay,
                weeklyTarget: member.weeklyHoursTarget
            ))
        }
        
        var teamAverageHoursPerDay = 0.0
        if totalDaysWorked > 0 {
            teamAverageHoursPerDay = totalTeamHours / Double(totalDaysWorked)
        }
        
        var teamAverageHoursPerMember = 0.0
        if team.members.count > 0 {
            teamAverageHoursPerMember = totalTeamHours / Double(team.members.count)
        }
        
        return TeamHoursStatsResponse(
            teamId: teamID,
            teamName: team.name,
            period: period,
            startDate: startDate,
            endDate: now,
            totalTeamHours: totalTeamHours,
            averageHoursPerDay: teamAverageHoursPerDay,
            averageHoursPerMember: teamAverageHoursPerMember,
            memberStats: memberStats
        )
    }
    
    // Statistiques d'heures d'un employé pour les managers
    func getEmployeeHoursStats(req: Request) async throws -> EmployeeHoursStatsResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        // Récupérer la période depuis les query params
        let period = req.query[String.self, at: "period"] ?? "month"
        
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case "week":
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case "month":
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        default:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        }
        
        // Récupérer toutes les entrées de temps
        let timeEntries = try await TimeEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$createdAt >= startDate)
            .filter(\.$status == "completed")
            .sort(\.$arrival, .ascending)
            .all()
        
        var totalHours = 0.0
        var overtimeHours = 0.0
        for entry in timeEntries {
            if let hours = entry.hoursWorked {
                totalHours = totalHours + hours
            }
            if entry.isOvertime {
                overtimeHours = overtimeHours + entry.overtimeHours
            }
        }
        
        var uniqueDays: [Date] = []
        for entry in timeEntries {
            let day = calendar.startOfDay(for: entry.arrival)
            if !uniqueDays.contains(day) {
                uniqueDays.append(day)
            }
        }
        let daysWorked = uniqueDays.count
        
        var averageHoursPerDay = 0.0
        if daysWorked > 0 {
            averageHoursPerDay = totalHours / Double(daysWorked)
        }
        
        var dailyStats: [DailyHoursStats] = []
        var weeklyStats: [WeeklyHoursStats] = []
        
        for day in uniqueDays.sorted() {
            var dayTotal = 0.0
            var dayOvertime = 0.0
            var dayCount = 0
            
            for entry in timeEntries {
                let entryDay = calendar.startOfDay(for: entry.arrival)
                if entryDay == day {
                    if let hours = entry.hoursWorked {
                        dayTotal = dayTotal + hours
                    }
                    if entry.isOvertime {
                        dayOvertime = dayOvertime + entry.overtimeHours
                    }
                    dayCount = dayCount + 1
                }
            }
            
            dailyStats.append(DailyHoursStats(
                date: day,
                totalHours: dayTotal,
                overtimeHours: dayOvertime,
                entriesCount: dayCount
            ))
        }
        
        return EmployeeHoursStatsResponse(
            userId: userID,
            userName: user.fullName,
            period: period,
            startDate: startDate,
            endDate: now,
            summary: EmployeeHoursSummary(
                totalHours: totalHours,
                overtimeHours: overtimeHours,
                daysWorked: daysWorked,
                averageHoursPerDay: averageHoursPerDay,
                weeklyTarget: user.weeklyHoursTarget
            ),
            dailyStats: dailyStats,
            weeklyStats: weeklyStats
        )
    }
}

struct UserDashboardResponse: Content {
    let user: UserResponse
    let currentStatus: String
    let activeEntry: TimeEntryResponse?
    let stats: DashboardStats
    let performance: PerformanceResponse?
    let teams: [DashboardTeamResponse]
    let weeklyTarget: Double
}

struct DashboardStats: Content {
    let totalHoursThisMonth: Double
    let totalHoursThisWeek: Double
    let averageHoursPerDayMonth: Double
    let averageHoursPerDayWeek: Double
    let daysWorkedThisMonth: Int
    let daysWorkedThisWeek: Int
    let overtimeHours: Double
}

struct TeamHoursStatsResponse: Content {
    let teamId: UUID
    let teamName: String
    let period: String
    let startDate: Date
    let endDate: Date
    let totalTeamHours: Double
    let averageHoursPerDay: Double
    let averageHoursPerMember: Double
    let memberStats: [MemberHoursStats]
}

struct MemberHoursStats: Content {
    let userId: UUID
    let userName: String
    let totalHours: Double
    let daysWorked: Int
    let averageHoursPerDay: Double
    let weeklyTarget: Double
}

struct EmployeeHoursStatsResponse: Content {
    let userId: UUID
    let userName: String
    let period: String
    let startDate: Date
    let endDate: Date
    let summary: EmployeeHoursSummary
    let dailyStats: [DailyHoursStats]
    let weeklyStats: [WeeklyHoursStats]
}

struct EmployeeHoursSummary: Content {
    let totalHours: Double
    let overtimeHours: Double
    let daysWorked: Int
    let averageHoursPerDay: Double
    let weeklyTarget: Double
}

struct DailyHoursStats: Content {
    let date: Date
    let totalHours: Double
    let overtimeHours: Double
    let entriesCount: Int
}

struct WeeklyHoursStats: Content {
    let weekStart: Date
    let totalHours: Double
    let overtimeHours: Double
    let daysWorked: Int
    let averageHoursPerDay: Double
}

struct DashboardTeamResponse: Content {
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

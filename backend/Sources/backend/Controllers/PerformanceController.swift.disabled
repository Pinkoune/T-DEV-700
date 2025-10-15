import Vapor
import FirebaseFirestore

struct PerformanceController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let performances = routes.grouped("api", "performances")
        
        // Routes protégées par JWT
        let protected = performances.grouped(JWTAuthMiddleware())
        
        // Routes CRUD
        protected.get(use: getAllPerformances)
        protected.post(use: createPerformance)
        protected.group(":performanceID") { performance in
            performance.get(use: getPerformance)
            performance.put(use: updatePerformance)
            performance.delete(use: deletePerformance)
        }
        
        // Routes spécialisées
        protected.get("by-user", ":userID", use: getPerformancesByUser)
        protected.get("by-period", ":period", use: getPerformancesByPeriod)
        protected.get("latest", ":userID", use: getLatestPerformance)
        protected.get("trends", ":userID", use: getPerformanceTrends)
        
        // Routes de statistiques et analyses
        protected.get("analytics", "overview", use: getPerformanceOverview)
        protected.get("analytics", "team", ":teamID", use: getTeamPerformanceAnalytics)
        protected.get("analytics", "rankings", use: getPerformanceRankings)
        protected.get("analytics", "alerts", use: getPerformanceAlerts)
        
        // Routes de calcul automatique
        protected.post("calculate", ":userID", use: calculateUserPerformance)
        protected.post("calculate-team", ":teamID", use: calculateTeamPerformance)
    }
    
    
    // Operations CRUD
    
    /// GET /api/performances - Récupére toutes les performances
    func getAllPerformances(req: Request) async throws -> [PerformanceResponse] {
        let firestore = req.application.firestore
        let limit = req.query["limit"] ?? 50
        
        do {
            let snapshot = try await firestore.collection("performances")
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
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
    
    /// POST /api/performances - Crée une nouvelle performance
    func createPerformance(req: Request) async throws -> PerformanceResponse {
        try Performance.validate(content: req)
        let performanceData = try req.content.decode(CreatePerformanceRequest.self)
        
        let performance = Performance(
            userId: performanceData.userId,
            period: performanceData.period,
            index: performanceData.index
        )
        
        let firestore = req.application.firestore
        
        do {
            // Vérifie que l'utilisateur existe
            let userDoc = try await firestore.collection("users").document(performanceData.userId).getDocument()
            guard userDoc.exists else {
                throw Abort(.badRequest, reason: "Utilisateur non trouvé")
            }
            
            // Vérifie qu'il n'y a pas déjà une performance pour cette période
            let existingPerformances = try await firestore.collection("performances")
                .whereField("userId", isEqualTo: performanceData.userId)
                .whereField("period", isEqualTo: performanceData.period)
                .getDocuments()
            
            if !existingPerformances.documents.isEmpty {
                throw Abort(.conflict, reason: "Une performance existe déjà pour cette période")
            }
            
            let docRef = try await firestore.collection("performances").addDocument(data: [
                "userId": performance.userId,
                "period": performance.period,
                "index": performance.index,
                "createdAt": performance.createdAt,
                "updatedAt": performance.updatedAt
            ])
            
            var createdPerformance = performance
            createdPerformance.id = docRef.documentID
            
            return PerformanceResponse(from: createdPerformance)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la création de la performance: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/performances/:performanceID - Récupére une performance spécifique
    func getPerformance(req: Request) async throws -> PerformanceResponse {
        guard let performanceID = req.parameters.get("performanceID") else {
            throw Abort(.badRequest, reason: "ID performance manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let document = try await firestore.collection("performances").document(performanceID).getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Performance non trouvée")
            }
            
            guard var performance = try? document.data(as: Performance.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de la performance")
            }
            
            performance.id = document.documentID
            return PerformanceResponse(from: performance)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération de la performance: \(error.localizedDescription)")
        }
    }
    
    /// PUT /api/performances/:performanceID - Met à jour une performance
    func updatePerformance(req: Request) async throws -> PerformanceResponse {
        guard let performanceID = req.parameters.get("performanceID") else {
            throw Abort(.badRequest, reason: "ID performance manquant")
        }
        
        let updateData = try req.content.decode(UpdatePerformanceRequest.self)
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("performances").document(performanceID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Performance non trouvée")
            }
            
            guard var existingPerformance = try? document.data(as: Performance.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de la performance")
            }
            
            // Mise à jour des champs modifiés
            var updateFields: [String: Any] = ["updatedAt": Date()]
            
            if let index = updateData.index {
                existingPerformance.index = index
                updateFields["index"] = index
            }
            if let period = updateData.period {
                existingPerformance.period = period
                updateFields["period"] = period
            }
            
            try await docRef.updateData(updateFields)
            
            existingPerformance.id = performanceID
            existingPerformance.updatedAt = Date()
            
            return PerformanceResponse(from: existingPerformance)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la mise à jour de la performance: \(error.localizedDescription)")
        }
    }
    
    /// DELETE /api/performances/:performanceID - Supprime une performance
    func deletePerformance(req: Request) async throws -> HTTPStatus {
        guard let performanceID = req.parameters.get("performanceID") else {
            throw Abort(.badRequest, reason: "ID performance manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("performances").document(performanceID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Performance non trouvée")
            }
            
            try await docRef.delete()
            
            return .noContent
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la suppression de la performance: \(error.localizedDescription)")
        }
    }
    
    // ROUTES Spécialisées
    
    /// GET /api/performances/by-user/:userID - Performances par utilisateur
    func getPerformancesByUser(req: Request) async throws -> [PerformanceResponse] {
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
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des performances utilisateur: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/performances/by-period/:period - Performances par période
    func getPerformancesByPeriod(req: Request) async throws -> [PerformanceResponse] {
        guard let period = req.parameters.get("period") else {
            throw Abort(.badRequest, reason: "Période manquante")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("performances")
                .whereField("period", isEqualTo: period)
                .order(by: "index", descending: true)
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
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des performances par période: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/performances/latest/:userID - Dernière performance d'un utilisateur
    func getLatestPerformance(req: Request) async throws -> LatestPerformanceResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("performances")
                .whereField("userId", isEqualTo: userID)
                .order(by: "createdAt", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if let document = snapshot.documents.first {
                guard var performance = try? document.data(as: Performance.self) else {
                    throw Abort(.internalServerError, reason: "Erreur lors du décodage de la performance")
                }
                
                performance.id = document.documentID
                return LatestPerformanceResponse(
                    hasPerformance: true,
                    performance: PerformanceResponse(from: performance)
                )
            } else {
                return LatestPerformanceResponse(
                    hasPerformance: false,
                    performance: nil
                )
            }
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération de la dernière performance: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/performances/trends/:userID - Tendances de performance d'un utilisateur
    func getPerformanceTrends(req: Request) async throws -> PerformanceTrendsResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("performances")
                .whereField("userId", isEqualTo: userID)
                .order(by: "createdAt", descending: false)
                .getDocuments()
            
            var performances: [PerformanceResponse] = []
            var totalIndex = 0.0
            var count = 0
            
            for document in snapshot.documents {
                if let performance = try? document.data(as: Performance.self) {
                    var performanceWithId = performance
                    performanceWithId.id = document.documentID
                    performances.append(PerformanceResponse(from: performanceWithId))
                    
                    totalIndex += performance.index
                    count += 1
                }
            }
            
            let averagePerformance = count > 0 ? totalIndex / Double(count) : 0.0
            
            // Calcule la tendance (amélioration/dégradation)
            var trend = "stable"
            if performances.count >= 2 {
                let recent = performances.suffix(3).map { $0.index }
                let older = performances.prefix(max(1, performances.count - 3)).map { $0.index }
                
                let recentAvg = recent.reduce(0, +) / Double(recent.count)
                let olderAvg = older.reduce(0, +) / Double(older.count)
                
                if recentAvg > olderAvg + 5 {
                    trend = "improving"
                } else if recentAvg < olderAvg - 5 {
                    trend = "declining"
                }
            }
            
            return PerformanceTrendsResponse(
                userId: userID,
                performances: performances,
                averagePerformance: averagePerformance,
                trend: trend,
                totalEvaluations: count
            )
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de l'analyse des tendances: \(error.localizedDescription)")
        }
    }
    
    // ROUTES Analytiques
    
    /// GET /api/performances/analytics/overview - Vue d'ensemble des performances
    func getPerformanceOverview(req: Request) async throws -> PerformanceOverviewResponse {
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("performances").getDocuments()
            
            var totalPerformances = 0
            var totalIndex = 0.0
            var excellentCount = 0
            var poorCount = 0
            var userPerformances: [String: [Double]] = [:]
            
            for document in snapshot.documents {
                if let performance = try? document.data(as: Performance.self) {
                    totalPerformances += 1
                    totalIndex += performance.index
                    
                    if performance.isExcellent {
                        excellentCount += 1
                    } else if performance.index < 40 {
                        poorCount += 1
                    }
                    
                    userPerformances[performance.userId, default: []].append(performance.index)
                }
            }
            
            let averagePerformance = totalPerformances > 0 ? totalIndex / Double(totalPerformances) : 0.0
            let excellentPercentage = totalPerformances > 0 ? (Double(excellentCount) / Double(totalPerformances)) * 100 : 0.0
            let poorPerformancePercentage = totalPerformances > 0 ? (Double(poorCount) / Double(totalPerformances)) * 100 : 0.0
            
            return PerformanceOverviewResponse(
                totalEvaluations: totalPerformances,
                averagePerformance: averagePerformance,
                excellentPerformancePercentage: excellentPercentage,
                poorPerformancePercentage: poorPerformancePercentage,
                totalUsers: userPerformances.count
            )
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la génération de la vue d'ensemble: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/performances/analytics/team/:teamID - Analyse de performance d'équipe
    func getTeamPerformanceAnalytics(req: Request) async throws -> TeamPerformanceAnalyticsResponse {
        guard let teamID = req.parameters.get("teamID") else {
            throw Abort(.badRequest, reason: "ID équipe manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            // Récupére l'équipe
            let teamDoc = try await firestore.collection("teams").document(teamID).getDocument()
            guard teamDoc.exists, let team = try? teamDoc.data(as: Team.self) else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            var memberPerformances: [MemberPerformanceAnalytics] = []
            var totalTeamPerformance = 0.0
            var evaluatedMembers = 0
            
            for memberID in team.members {
                // Récupére l'utilisateur
                let userDoc = try await firestore.collection("users").document(memberID).getDocument()
                guard userDoc.exists, let user = try? userDoc.data(as: User.self) else {
                    continue
                }
                
                // Récupére les performances du membre
                let performanceSnapshot = try await firestore.collection("performances")
                    .whereField("userId", isEqualTo: memberID)
                    .order(by: "createdAt", descending: true)
                    .getDocuments()
                
                var memberTotal = 0.0
                var memberCount = 0
                var latestPerformance: Double?
                
                for performanceDoc in performanceSnapshot.documents {
                    if let performance = try? performanceDoc.data(as: Performance.self) {
                        memberTotal += performance.index
                        memberCount += 1
                        
                        if latestPerformance == nil {
                            latestPerformance = performance.index
                        }
                    }
                }
                
                let memberAverage = memberCount > 0 ? memberTotal / Double(memberCount) : 0.0
                
                if memberCount > 0 {
                    totalTeamPerformance += memberAverage
                    evaluatedMembers += 1
                }
                
                memberPerformances.append(MemberPerformanceAnalytics(
                    userId: memberID,
                    userName: user.fullName,
                    isManager: team.isManager(memberID),
                    averagePerformance: memberAverage,
                    latestPerformance: latestPerformance,
                    totalEvaluations: memberCount
                ))
            }
            
            let teamAveragePerformance = evaluatedMembers > 0 ? totalTeamPerformance / Double(evaluatedMembers) : 0.0
            
            return TeamPerformanceAnalyticsResponse(
                teamId: teamID,
                teamName: team.name,
                memberPerformances: memberPerformances,
                teamAveragePerformance: teamAveragePerformance,
                totalMembers: team.memberCount,
                evaluatedMembers: evaluatedMembers
            )
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de l'analyse de performance d'équipe: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/performances/analytics/rankings - Classement des performances
    func getPerformanceRankings(req: Request) async throws -> [UserRankingResponse] {
        let firestore = req.application.firestore
        let period = req.query["period"] as String? ?? "month"
        
        do {
            let snapshot = try await firestore.collection("performances")
                .whereField("period", isEqualTo: period)
                .order(by: "index", descending: true)
                .getDocuments()
            
            var userRankings: [String: (totalIndex: Double, count: Int, latestIndex: Double)] = [:]
            
            for document in snapshot.documents {
                if let performance = try? document.data(as: Performance.self) {
                    let existing = userRankings[performance.userId] ?? (0.0, 0, 0.0)
                    userRankings[performance.userId] = (
                        existing.totalIndex + performance.index,
                        existing.count + 1,
                        performance.index
                    )
                }
            }
            
            var rankings: [UserRankingResponse] = []
            
            for (userId, stats) in userRankings {
                // Récupére les détails de l'utilisateur
                let userDoc = try await firestore.collection("users").document(userId).getDocument()
                if userDoc.exists, let user = try? userDoc.data(as: User.self) {
                    let averagePerformance = stats.count > 0 ? stats.totalIndex / Double(stats.count) : 0.0
                    
                    rankings.append(UserRankingResponse(
                        userId: userId,
                        userName: user.fullName,
                        department: user.department,
                        averagePerformance: averagePerformance,
                        latestPerformance: stats.latestIndex,
                        totalEvaluations: stats.count
                    ))
                }
            }
            
            // Trie par performance moyenne décroissante
            rankings.sort { $0.averagePerformance > $1.averagePerformance }
            
            // Ajoute les rangs
            for (index, _) in rankings.enumerated() {
                rankings[index].rank = index + 1
            }
            
            return rankings
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la génération du classement: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/performances/analytics/alerts - Alertes de performance
    func getPerformanceAlerts(req: Request) async throws -> [PerformanceAlertResponse] {
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("performances")
                .whereField("index", isLessThan: 40.0)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var alerts: [PerformanceAlertResponse] = []
            
            for document in snapshot.documents {
                if let performance = try? document.data(as: Performance.self) {
                    // Récupérer les détails de l'utilisateur
                    let userDoc = try await firestore.collection("users").document(performance.userId).getDocument()
                    if userDoc.exists, let user = try? userDoc.data(as: User.self) {
                        
                        var alertType = "low_performance"
                        var message = "Performance faible détectée"
                        
                        if performance.index < 20 {
                            alertType = "critical_performance"
                            message = "Performance critique nécessitant une attention immédiate"
                        }
                        
                        alerts.append(PerformanceAlertResponse(
                            userId: performance.userId,
                            userName: user.fullName,
                            department: user.department,
                            performanceIndex: performance.index,
                            period: performance.period,
                            alertType: alertType,
                            message: message,
                            createdAt: performance.createdAt
                        ))
                    }
                }
            }
            
            return alerts
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la génération des alertes: \(error.localizedDescription)")
        }
    }
    
    // ROUTES Calculatrices
    
    /// POST /api/performances/calculate/:userID - Calcule automatiquement la performance d'un utilisateur
    func calculateUserPerformance(req: Request) async throws -> PerformanceResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let calculationData = try req.content.decode(CalculatePerformanceRequest.self)
        let firestore = req.application.firestore
        
        do {
            // Vérifie que l'utilisateur existe
            let userDoc = try await firestore.collection("users").document(userID).getDocument()
            guard userDoc.exists, let user = try? userDoc.data(as: User.self) else {
                throw Abort(.notFound, reason: "Utilisateur non trouvé")
            }
            
            // Calcule la performance basée sur les heures travaillées
            let calendar = Calendar.current
            let endDate = Date()
            let startDate: Date
            
            switch calculationData.period {
            case "day":
                startDate = calendar.startOfDay(for: endDate)
            case "week":
                startDate = calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? endDate
            case "month":
                startDate = calendar.dateInterval(of: .month, for: endDate)?.start ?? endDate
            default:
                throw Abort(.badRequest, reason: "Période invalide")
            }
            
            // Récupére les entrées de temps pour la période
            let timeEntriesSnapshot = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: userID)
                .whereField("arrival", isGreaterThanOrEqualTo: startDate)
                .whereField("arrival", isLessThanOrEqualTo: endDate)
                .whereField("status", isEqualTo: "completed")
                .getDocuments()
            
            var totalHours = 0.0
            var expectedHours = 0.0
            
            // Calcule les heures travaillées et attendues
            for document in timeEntriesSnapshot.documents {
                if let timeEntry = try? document.data(as: TimeEntry.self) {
                    totalHours += timeEntry.hoursWorked ?? 0
                }
            }
            
            // Calcule les heures attendues selon la période
            switch calculationData.period {
            case "day":
                expectedHours = user.weeklyHoursTarget / 5.0 // Supposer 5 jours de travail
            case "week":
                expectedHours = user.weeklyHoursTarget
            case "month":
                expectedHours = user.weeklyHoursTarget * 4.0 // Approximation de 4 semaines
            default:
                expectedHours = user.weeklyHoursTarget
            }
            
            // Calcule l'index de performance (0-100)
            let performanceIndex = min(100.0, (totalHours / expectedHours) * 100.0)
            
            // Crée la performance
            let performance = Performance(
                userId: userID,
                period: calculationData.period,
                index: performanceIndex
            )
            
            let docRef = try await firestore.collection("performances").addDocument(data: [
                "userId": performance.userId,
                "period": performance.period,
                "index": performance.index,
                "createdAt": performance.createdAt,
                "updatedAt": performance.updatedAt
            ])
            
            var createdPerformance = performance
            createdPerformance.id = docRef.documentID
            
            return PerformanceResponse(from: createdPerformance)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors du calcul de la performance: \(error.localizedDescription)")
        }
    }
    
    /// POST /api/performances/calculate-team/:teamID - Calcule la performance d'une équipe
    func calculateTeamPerformance(req: Request) async throws -> [PerformanceResponse] {
        guard let teamID = req.parameters.get("teamID") else {
            throw Abort(.badRequest, reason: "ID équipe manquant")
        }
        
        let calculationData = try req.content.decode(CalculatePerformanceRequest.self)
        let firestore = req.application.firestore
        
        do {
            // Récupére l'équipe
            let teamDoc = try await firestore.collection("teams").document(teamID).getDocument()
            guard teamDoc.exists, let team = try? teamDoc.data(as: Team.self) else {
                throw Abort(.notFound, reason: "Équipe non trouvée")
            }
            
            var teamPerformances: [PerformanceResponse] = []
            
            // Calcule la performance pour chaque membre
            for memberID in team.members {
                // Crée une requête temporaire pour calculer la performance du membre
                let memberReq = Request(application: req.application, on: req.eventLoop)
                memberReq.parameters.set("userID", to: memberID)
                try memberReq.content.encode(calculationData)
                
                do {
                    let memberPerformance = try await calculateUserPerformance(req: memberReq)
                    teamPerformances.append(memberPerformance)
                } catch {
                    // Continue même si un membre échoue
                    continue
                }
            }
            
            return teamPerformances
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors du calcul de la performance d'équipe: \(error.localizedDescription)")
        }
    }

// MODELES de Requêtes et Réponses

struct CreatePerformanceRequest: Content, Validatable {
    let userId: String
    let period: String
    let index: Double
    
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: String.self, is: !.empty)
        validations.add("period", as: String.self, is: .in("day", "week", "month"))
        validations.add("index", as: Double.self, is: .range(0...100))
    }
}

struct UpdatePerformanceRequest: Content {
    let period: String?
    let index: Double?
}

struct CalculatePerformanceRequest: Content, Validatable {
    let period: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("period", as: String.self, is: .in("day", "week", "month"))
    }
}

struct PerformanceTrendsResponse: Content {
    let userId: String
    let performances: [PerformanceResponse]
    let averagePerformance: Double
    let trend: String // "improving", "declining", "stable"
    let totalEvaluations: Int
}

struct PerformanceOverviewResponse: Content {
    let totalEvaluations: Int
    let averagePerformance: Double
    let excellentPerformancePercentage: Double
    let poorPerformancePercentage: Double
    let totalUsers: Int
}

struct TeamPerformanceAnalyticsResponse: Content {
    let teamId: String
    let teamName: String
    let memberPerformances: [MemberPerformanceAnalytics]
    let teamAveragePerformance: Double
    let totalMembers: Int
    let evaluatedMembers: Int
}

struct MemberPerformanceAnalytics: Content {
    let userId: String
    let userName: String
    let isManager: Bool
    let averagePerformance: Double
    let latestPerformance: Double?
    let totalEvaluations: Int
}

struct UserRankingResponse: Content {
    let userId: String
    let userName: String
    let department: String?
    let averagePerformance: Double
    let latestPerformance: Double
    let totalEvaluations: Int
    var rank: Int = 0
}

struct PerformanceAlertResponse: Content {
    let userId: String
    let userName: String
    let department: String?
    let performanceIndex: Double
    let period: String
    let alertType: String // "low_performance", "critical_performance"
    let message: String
    let createdAt: Date
}

struct LatestPerformanceResponse: Content {
    let hasPerformance: Bool
    let performance: PerformanceResponse?
}
}

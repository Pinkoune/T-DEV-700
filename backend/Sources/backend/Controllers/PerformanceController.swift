import Vapor
import Fluent

struct PerformanceController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let performances = routes.grouped("performances")
        
        performances.get(use: getAllPerformances)
        performances.post(use: createPerformance)
        performances.group(":performanceID") { performance in
            performance.get(use: getPerformance)
            performance.put(use: updatePerformance)
            performance.delete(use: deletePerformance)
        }
        performances.get("by-user", ":userID", use: getPerformancesByUser)
        performances.get("latest", ":userID", use: getLatestPerformance)
    }

    /// GET /performances - Récupère toutes les performances
    func getAllPerformances(req: Request) async throws -> [PerformanceResponse] {
        let limit = req.query[Int.self, at: "limit"] ?? 50
        
        let performances = try await Performance.query(on: req.db)
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .all()

        return performances.map { PerformanceResponse(from: $0) }
    }

    /// GET /performances/:performanceID - Récupère une performance par ID
    func getPerformance(req: Request) async throws -> PerformanceResponse {
        guard let performanceID = req.parameters.get("performanceID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID de performance invalide")
        }

        guard let performance = try await Performance.query(on: req.db)
            .filter(\.$id == performanceID)
            .with(\.$user)
            .first()
        else {
            throw Abort(.notFound, reason: "Performance non trouvée")
        }

        return PerformanceResponse(from: performance)
    }
    
    /// POST /performances - Crée une nouvelle performance
    func createPerformance(req: Request) async throws -> PerformanceResponse {
        try CreatePerformanceRequest.validate(content: req)
        let performanceData = try req.content.decode(CreatePerformanceRequest.self)
        
        // Vérification de l'existence de notre utilisateur dans la db.
        guard let _ = try await User.find(performanceData.userId, on: req.db) else {
            throw Abort(.badRequest, reason: "Utilisateur non trouvé")
        }

        // Vérification de l'existence d'une performance pour cette période
        let existingPerformance = try await Performance.query(on: req.db)
            .filter(\.$user.$id == performanceData.userId)
            .filter(\.$period == performanceData.period)
            .first()

        if existingPerformance != nil {
            throw Abort(.conflict, reason: "Une performance existe déjà pour cette période")
        }

        // Mise en place et création de la nouvelle performance.
        let performance = Performance(
            userId: performanceData.userId,
            period: performanceData.period,
            index: performanceData.index
        )
        
        try await performance.save(on: req.db)
        try await performance.$user.load(on: req.db)
        
        return PerformanceResponse(from: performance)
    }
    
    /// PUT /performances/:performanceID - Met à jour une performance pour un utilisateur spécifique.
    func updatePerformance(req: Request) async throws -> PerformanceResponse {
        guard let performanceID = req.parameters.get("performanceID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID de performance invalide")
        }
        
        guard let performance = try await Performance.find(performanceID, on: req.db) else {
            throw Abort(.notFound, reason: "Performance non trouvée")
        }

        let updateData = try req.content.decode(UpdatePerformanceRequest.self)

        if let period = updateData.period {
            performance.period = period
        }
        if let index = updateData.index {
            performance.index = index
        }

        try await performance.save(on: req.db)
        try await performance.$user.load(on: req.db)

        return PerformanceResponse(from: performance)
    }
    
    /// DELETE /performances/:performanceID - Supprime une performance pour un utilisateur spécifique.
    func deletePerformance(req: Request) async throws -> HTTPStatus {
        guard let performanceID = req.parameters.get("performanceID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID de performance invalide")
        }
        
        guard let performance = try await Performance.find(performanceID, on: req.db) else {
            throw Abort(.notFound, reason: "Performance non trouvée")
        }

        try await performance.delete(on: req.db)
        return .noContent
    }

    
    /// GET /performances/by-user/:userID - Récupèration de toutes les performances d'un utilisateur spécifique.
    func getPerformancesByUser(req: Request) async throws -> [PerformanceResponse] {
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
    
    /// GET /performances/latest/:userID - Récupèraion de la dernière performance d'un utilisateur spécifique à l'aide d'un filtre.
    func getLatestPerformance(req: Request) async throws -> PerformanceResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID utilisateur invalide")
        }
        
        guard let performance = try await Performance.query(on: req.db)
            .filter(\.$user.$id == userID)
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucune performance trouvée pour cet utilisateur")
        }

        return PerformanceResponse(from: performance)
    }
}

struct CreatePerformanceRequest: Content, Validatable {
    let userId: UUID
    let period: String
    let index: Double
    
    static func validations(_ validations: inout Validations) {
        validations.add("period", as: String.self, is: .in("day", "week", "month"))
        validations.add("index", as: Double.self, is: .range(0...100))
    }
}

struct UpdatePerformanceRequest: Content {
    let period: String?
    let index: Double?
}

struct PerformanceResponse: Content {
    let id: UUID?
    let userId: UUID
    let userName: String
    let period: String
    let index: Double
    let performanceLevel: String
    let isExcellent: Bool
    let createdAt: Date?
    let updatedAt: Date?

    init(from performance: Performance) {
        self.id = performance.id
        self.userId = performance.$user.id
        self.userName = performance.user.fullName
        self.period = performance.period
        self.index = performance.index
        self.performanceLevel = performance.performanceLevel
        self.isExcellent = performance.isExcellent
        self.createdAt = performance.createdAt
        self.updatedAt = performance.updatedAt
    }
}

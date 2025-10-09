import Vapor

struct SimpleUserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        
        // Routes CRUD de base
        users.get(use: getAllUsers)
        users.post(use: createUser)
        users.group(":userID") { user in
            user.get(use: getUser)
            user.put(use: updateUser)
            user.delete(use: deleteUser)
        }
        
        // Routes spécialisées
        users.get("active", use: getActiveUsers)
        users.get("by-role", ":role", use: getUsersByRole)
    }
    
    // Opérations CRUD
    
    func getAllUsers(req: Request) async throws -> [UserResponse] {
        let users = await MockDataService.shared.getAllUsers()
        return users.map { UserResponse(from: $0) }
    }
    
    func createUser(req: Request) async throws -> UserResponse {
        let userData = try req.content.decode(CreateUserRequest.self)
        
        let user = User(
            firstName: userData.firstName,
            lastName: userData.lastName,
            email: userData.email,
            phone: userData.phone,
            role: userData.role ?? "employee",
            department: userData.department,
            position: userData.position,
            weeklyHoursTarget: userData.weeklyHoursTarget ?? 35.0
        )
        
        let createdUser = await MockDataService.shared.createUser(user)
        return UserResponse(from: createdUser)
    }
    
    func getUser(req: Request) async throws -> UserResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        guard let user = await MockDataService.shared.getUser(id: userID) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        return UserResponse(from: user)
    }
    
    func updateUser(req: Request) async throws -> UserResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        guard let existingUser = await MockDataService.shared.getUser(id: userID) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        let updateData = try req.content.decode(UpdateUserRequest.self)
        
        var updatedUser = existingUser
        if let firstName = updateData.firstName { updatedUser.firstName = firstName }
        if let lastName = updateData.lastName { updatedUser.lastName = lastName }
        if let email = updateData.email { updatedUser.email = email }
        if let phone = updateData.phone { updatedUser.phone = phone }
        if let role = updateData.role { updatedUser.role = role }
        if let department = updateData.department { updatedUser.department = department }
        if let position = updateData.position { updatedUser.position = position }
        if let weeklyHoursTarget = updateData.weeklyHoursTarget { updatedUser.weeklyHoursTarget = weeklyHoursTarget }
        if let isActive = updateData.isActive { updatedUser.isActive = isActive }
        
        guard let finalUser = await MockDataService.shared.updateUser(id: userID, updatedUser) else {
            throw Abort(.internalServerError, reason: "Erreur lors de la mise à jour")
        }
        
        return UserResponse(from: finalUser)
    }
    
    func deleteUser(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        guard await MockDataService.shared.deleteUser(id: userID) else {
            throw Abort(.notFound, reason: "Utilisateur non trouvé")
        }
        
        return .noContent
    }
    
    func getActiveUsers(req: Request) async throws -> [UserResponse] {
        let users = await MockDataService.shared.getAllUsers().filter { $0.isActive }
        return users.map { UserResponse(from: $0) }
    }
    
    func getUsersByRole(req: Request) async throws -> [UserResponse] {
        guard let role = req.parameters.get("role") else {
            throw Abort(.badRequest, reason: "Rôle manquant")
        }
        
        let users = await MockDataService.shared.getAllUsers().filter { $0.role == role && $0.isActive }
        return users.map { UserResponse(from: $0) }
    }
}

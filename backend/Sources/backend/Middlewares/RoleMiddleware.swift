import Vapor

struct AdminMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "Non authentifié")
        }
        
        if user.role != "admin" {
            throw Abort(.forbidden, reason: "Accès réservé aux administrateurs")
        }
        
        return try await next.respond(to: request)
    }
}

struct ManagerMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "Non authentifié")
        }
        
        if user.role != "manager" && user.role != "admin" {
            throw Abort(.forbidden, reason: "Accès réservé aux managers")
        }
        
        return try await next.respond(to: request)
    }
}

struct EmployeeMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "Non authentifié")
        }
        
        return try await next.respond(to: request)
    }
}

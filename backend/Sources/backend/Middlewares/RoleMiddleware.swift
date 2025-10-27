import Vapor

struct ManagerMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "Non authentifié")
        }
        
        if user.role != "manager" {
            throw Abort(.forbidden, reason: "Accès réservé")
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

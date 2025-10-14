import Vapor

struct RequireRole: AsyncMiddleware {
    let requiredRoles: [String]
    
    init(_ roles: String...) {
        self.requiredRoles = roles
    }
    
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let payload = request.auth.get(UserPayload.self) else {
            throw Abort(.unauthorized, reason: "Authentification requise")
        }
        
        let hasRequiredRole = payload.roles.contains { requiredRoles.contains($0) }
        guard hasRequiredRole else {
            throw Abort(.forbidden, reason: "Permissions insuffisantes. Rôles requis: \(requiredRoles.joined(separator: ", "))")
        }
        
        return try await next.respond(to: request)
    }
}

// Extension pour faciliter l'utilisation
extension RoutesBuilder {
    func requireRole(_ roles: String...) -> RoutesBuilder {
        return self.grouped(RequireRole(roles))
    }
}
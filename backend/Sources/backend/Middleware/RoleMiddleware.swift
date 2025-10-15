import Vapor
import JWT

struct RoleMiddleware: AsyncMiddleware {
    let requiredRoles: [String]
    
    init(requiring roles: String...) {
        self.requiredRoles = roles
    }
    
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let payload = request.jwtPayload else {
            throw Abort(.unauthorized, reason: "Authentification requise")
        }
        
        guard requiredRoles.contains(payload.role) else {
            throw Abort(.forbidden, reason: "Rôle insuffisant. Requis: \(requiredRoles.joined(separator: " ou "))")
        }
        
        return try await next.respond(to: request)
    }
}

// Extension pour faciliter l'utilisation
extension RoutesBuilder {
    func requireRole(_ roles: String...) -> any RoutesBuilder {
        let roleArray = Array(roles)
        return self.grouped(RoleMiddleware(requiring: roleArray[0]))
    }
}

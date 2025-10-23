import Vapor
import JWT

struct JWTAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Token manquant")
        }
        
        do {
            let payload = try request.jwt.verify(token, as: UserJWTPayload.self)
            
            guard let userID = UUID(uuidString: payload.userId) else {
                throw Abort(.unauthorized, reason: "Token invalide")
            }
            
            guard let user = try await User.find(userID, on: request.db) else {
                throw Abort(.unauthorized, reason: "Utilisateur non trouvé")
            }
            
            if !user.isActive {
                throw Abort(.unauthorized, reason: "Compte désactivé")
            }
            
            request.auth.login(user)
            
            return try await next.respond(to: request)
        } catch {
            throw Abort(.unauthorized, reason: "Token invalide ou expiré")
        }
    }
}

struct UserJWTPayload: JWTKit.JWTPayload, Authenticatable {
    var userId: String
    var email: String
    var role: String
    var exp: ExpirationClaim
    
    func verify(using signer: JWTKit.JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}

import Vapor
import JWT

struct JWTService {
    let application: Application
    
    func generateToken(for user: User) throws -> String {
        let payload = UserPayload(user: user)
        return try application.jwt.signers.sign(payload)
    }
    
    func verifyToken(_ token: String) throws -> UserPayload {
        return try application.jwt.signers.verify(token, as: UserPayload.self)
    }
}

// Extension pour faciliter l'accès au payload JWT
extension Request {
    var jwtPayload: UserPayload? {
        return auth.get(UserPayload.self)
    }
    
    var authenticatedUserId: String? {
        return jwtPayload?.userId
    }
    
    var authenticatedUserRole: String? {
        return jwtPayload?.role
    }
    
    func requireAuthentication() throws -> UserPayload {
        guard let payload = jwtPayload else {
            throw Abort(.unauthorized, reason: "Authentification requise")
        }
        return payload
    }
}

// Authenticator JWT simple
struct JWTAuthenticator: AsyncRequestAuthenticator {
    func authenticate(request: Request) async throws {
        guard let bearerAuthorization = request.headers.bearerAuthorization else {
            return
        }
        
        do {
            let jwtService = JWTService(application: request.application)
            let payload = try jwtService.verifyToken(bearerAuthorization.token)
            request.auth.login(payload)
        } catch {
            request.logger.warning("Token JWT invalide: \(error)")
        }
    }
}

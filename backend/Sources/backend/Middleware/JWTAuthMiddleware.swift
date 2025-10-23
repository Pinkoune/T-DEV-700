import Vapor
import JWT

struct JWTAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Récupère le token du header Authorization
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Token JWT manquant dans le header Authorization")
        }

        // Vérification et décodage du token
        do {
            let payload = try await request.jwt.verify(token, as: UserPayload.self)
            request.auth.login(payload)
            return try await next.respond(to: request)
        } catch {
            throw Abort(.unauthorized, reason: "Token JWT invalide ou expiré")
        }
    }
}

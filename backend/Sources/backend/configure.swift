import Vapor
import JWT

// Configuration de l'application
public func configure(_ app: Application) async throws {
    // Configuration JWT Simple HMAC
    let jwtSecret = Environment.get("JWT_SECRET") ?? "your-secret-key-change-in-production"
    app.jwt.signers.use(.hs256(key: jwtSecret))
    
    // Configuration des middlewares de sécurité de base
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    // Enregistrement des routes
    try routes(app)
    
    print("API configurée avec JWT HMAC simple")
}


import Vapor
@preconcurrency import FirebaseFirestore
import FirebaseAuth
import SwiftDotenv

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Chargement du .env (optionnel pour les tests)
    // try Dotenv.load()
    
    // Configuration Firebase simple pour les tests
    // Note: Pour la production, vous devrez configurer Firebase avec vos credentials
    app.storage[FirestoreKey.self] = Firestore.firestore()
    
    // Commenté pour éviter les erreurs lors des tests
    // try await initializeFirestore(app: app)

    // register routes
    try routes(app)
}

// Clé pour stocker l'instance Firestore
struct FirestoreKey: StorageKey {
    typealias Value = Firestore
}

extension FirestoreKey.Value: @retroactive @unchecked Sendable {}

// Extension pour accéder facilement à Firestore
extension Application {
    var firestore: Firestore {
        get {
            guard let firestore = storage[FirestoreKey.self] else {
                fatalError("Firestore not configured. Call configure() first.")
            }
            return firestore
        }
        set {
            storage[FirestoreKey.self] = newValue
        }
    }
}

// Configuration de Firestore
// Note: Pour la production, configurez Firebase avec vos credentials appropriés

import SwiftDotenv
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Chargement du .env (optionnel pour les tests)
    // try Dotenv.load()

    // Configuration Firebase REST API client
    app.storage[FirebaseConfigKey.self] = FirebaseConfig(
        projectId: "mctime",
        databaseURL: "http://firebase:8080"
    )

    // Commenté pour éviter les erreurs lors des tests
    // try await initializeFirestore(app: app)

    // register routes
    try routes(app)
}

// Configuration Firebase
struct FirebaseConfig {
    let projectId: String
    let databaseURL: String

    var firestoreURL: String {
        return "\(databaseURL)/v1/projects/\(projectId)/databases/(default)/documents"
    }
}

// Clé pour stocker la configuration Firebase
struct FirebaseConfigKey: StorageKey {
    typealias Value = FirebaseConfig
}

// Extension pour accéder facilement à la configuration Firebase
extension Application {
    var firebase: FirebaseConfig {
        get {
            guard let config = storage[FirebaseConfigKey.self] else {
                fatalError("Firebase not configured. Call configure() first.")
            }
            return config
        }
        set {
            storage[FirebaseConfigKey.self] = newValue
        }
    }
}

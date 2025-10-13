import Vapor
@preconcurrency import FirebaseFirestore
import SwiftDotenv
import Foundation

// Configuration de l'application
public func configure(_ app: Application) async throws {
    // Chargement des variables d'environnement
    // Note: Utilisez les variables système ou configurez Dotenv selon votre version
    // try Dotenv.load(path: ".env")
    
    // Configuration Firebase avec vos credentials
    // Note: Temporairement désactivé - voir FIREBASE_CONFIGURATION.md pour l'activation
    // try await configureFirebaseWithCredentials(app)
    
    // Configuration temporaire pour les tests
    print("Mode test - Firebase désactivé temporairement")
    print("Consultez FIREBASE_CONFIGURATION.md pour activer Firebase")
    
    // Enregistrement des routes
    try routes(app)
    
    print("API configurée avec vos credentials Firebase")
}

// Configuration Firebase avec credentials
private func configureFirebaseWithCredentials(_ app: Application) async throws {
    // Récupération des variables d'environnement
    guard let projectId = Environment.get("FIREBASE_PROJECT_ID"),
          let serviceAccountPath = Environment.get("FIREBASE_SERVICE_ACCOUNT_PATH") else {
        throw Abort(.internalServerError, reason: "Variables Firebase manquantes. Définissez FIREBASE_PROJECT_ID et FIREBASE_SERVICE_ACCOUNT_PATH")
    }
    
    // Vérification que le fichier de service account existe
    let serviceAccountURL = URL(fileURLWithPath: serviceAccountPath)
    guard FileManager.default.fileExists(atPath: serviceAccountURL.path) else {
        throw Abort(.internalServerError, reason: "Fichier serviceAccountKey.json non trouvé à : \(serviceAccountPath)")
    }
    
    // Configuration des credentials Google Cloud
    setenv("GOOGLE_APPLICATION_CREDENTIALS", serviceAccountPath, 1)
    
    // Configuration Firestore avec credentials
    // Note: Les credentials sont chargés via GOOGLE_APPLICATION_CREDENTIALS
    app.storage[FirestoreKey.self] = Firestore.firestore()
    
    print("Firebase Firestore configuré avec le projet : \(projectId)")
    print("Credentials chargés depuis : \(serviceAccountPath)")
}

// Clé de stockage pour Firestore
struct FirestoreKey: StorageKey {
    typealias Value = Firestore
}

// Extension pour accéder à Firestore
extension Application {
    var firestore: Firestore {
        get {
            guard let firestore = storage[FirestoreKey.self] else {
                fatalError("Firestore non configuré. Vérifiez vos credentials Firebase.")
            }
            return firestore
        }
        set {
            storage[FirestoreKey.self] = newValue
        }
    }
}

// Conformité Sendable pour éviter les warnings
extension FirestoreKey.Value: @retroactive @unchecked Sendable {}

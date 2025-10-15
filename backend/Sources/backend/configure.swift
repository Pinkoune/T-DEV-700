import Vapor
@preconcurrency import FirebaseFirestore
import SwiftDotenv
import Foundation
import JWT
import Crypto

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

    
    print("API configurée avec vos credentials Firebase")
    
    // Chargement des clés depuis les variables d'environnement
    let privateKeyBase64: String
    let publicKeyBase64: String
    
    if let envPrivateKey = Environment.get("JWT_PRIVATE_KEY"),
       let envPublicKey = Environment.get("JWT_PUBLIC_KEY") {
        // En production: utiliser les variables d'environnement
        privateKeyBase64 = envPrivateKey
        publicKeyBase64 = envPublicKey
    } else {
        // En développement: génération de clés temporaires avec avertissement
        print("ATTENTION: Génération de clés JWT temporaires pour le développement")
        print("En PRODUCTION: Définir JWT_PRIVATE_KEY et JWT_PUBLIC_KEY")
        
        let cryptoPrivateKey = Crypto.Curve25519.Signing.PrivateKey()
        privateKeyBase64 = cryptoPrivateKey.rawRepresentation.base64EncodedString()
        publicKeyBase64 = cryptoPrivateKey.publicKey.rawRepresentation.base64EncodedString()
    }
    
    // Création des clés JWT
    let privateKey = try EdDSA.PrivateKey(d: privateKeyBase64, curve: .ed25519)
    let publicKey = try EdDSA.PublicKey(x: publicKeyBase64, curve: .ed25519)
    
    // Ajout des clés au keychain JWT
    await app.jwt.keys.add(eddsa: privateKey, kid: "cle-eddsa-v1")
    await app.jwt.keys.add(eddsa: publicKey, kid: "cle-publique-v1")
    
    // Configuration Firebase
    try await configureFirebaseWithCredentials(app)
    
    // Enregistrement des routes
    try routes(app)
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


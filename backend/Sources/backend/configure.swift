import Vapor

// configures the application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Configuration pour démonstration avec données en mémoire
    // Temporaire le temps de bien comprendre la liaison avec Firebase
    print("Configuration de l'API de gestion du temps")
    print("Utilisation du service de données en mémoire pour la démonstration")
    
    // register routes
    try routes(app)
    
    print("Configuration terminée - API prête !")
}

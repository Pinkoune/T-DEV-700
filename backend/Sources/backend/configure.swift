import Vapor
import Fluent
import FluentPostgresDriver

// Configuration de l'application
public func configure(_ app: Application) async throws {
    // Configuration PostgreSQL
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432
    let username = Environment.get("DATABASE_USERNAME") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    let database = Environment.get("DATABASE_NAME") ?? "vapor_database"
    
    app.databases.use(
        .postgres(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database
        ),
        as: .psql
    )
    
    // Migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateTeam())
    app.migrations.add(CreateTimeEntry())
    app.migrations.add(CreatePerformance())
    
    // Auto-migrate in development
    if app.environment == .development {
        try await app.autoMigrate()
    }
    
    // Enregistrement des routes
    try routes(app)
    
    app.logger.info("✅ PostgreSQL database configured")
    app.logger.info("📊 Database: \(database) on \(hostname):\(port)")
}

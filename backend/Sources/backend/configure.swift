import Vapor
import Fluent
import FluentPostgresDriver
import JWT

// Configuration de l'application
public func configure(_ app: Application) async throws {

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Configuration JWT
    let jwtSecret = Environment.get("JWT_SECRET") ?? "secret-key-change-in-production"
    app.jwt.signers.use(.hs256(key: [UInt8](jwtSecret.utf8)))

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
    app.migrations.add(AddPasswordHashToUser())
    app.migrations.add(AddExpectedArrivalTime())
    app.migrations.add(AddLoyaltyPointsToUser())
    app.migrations.add(AddInventoryToUser())
    app.migrations.add(AddBattlePassToUser())
    app.migrations.add(AddClaimedRewardsToUser()) // Add the missing migration
    app.migrations.add(SeedUsers()) // Move SeedUsers to the end
    
    if app.environment == .development {
        try await app.autoMigrate()
    }

    try routes(app)
    
    app.logger.info("PostgreSQL database configured")
    app.logger.info("Database: \(database) on \(hostname):\(port)")
}

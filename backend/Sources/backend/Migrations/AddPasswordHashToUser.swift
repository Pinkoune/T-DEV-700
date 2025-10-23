import Fluent

struct AddPasswordHashToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("password_hash", .string, .required, .sql(.default("$2b$12$defaulthash")))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("password_hash")
            .update()
    }
}

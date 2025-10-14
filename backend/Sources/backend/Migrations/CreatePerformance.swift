import Fluent

struct CreatePerformance: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("performances")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("period", .string, .required)
            .field("index", .double, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("performances").delete()
    }
}

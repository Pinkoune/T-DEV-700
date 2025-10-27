import Fluent

struct CreateTeam: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("teams")
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("members", .array(of: .uuid), .required)
            .field("manager_id", .uuid, .required)
            .field("color", .string, .required)
            .field("is_active", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("teams").delete()
    }
}

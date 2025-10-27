import Fluent

struct CreateTimeEntry: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("time_entries")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("arrival", .datetime, .required)
            .field("departure", .datetime)
            .field("hours_worked", .double)
            .field("status", .string, .required)
            .field("notes", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("time_entries").delete()
    }
}

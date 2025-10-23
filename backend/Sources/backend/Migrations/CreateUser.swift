import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("email", .string, .required)
            .field("phone", .string, .required)
            .field("role", .string, .required)
            .field("department", .string)
            .field("position", .string)
            .field("hire_date", .datetime)
            .field("is_active", .bool, .required)
            .field("weekly_hours_target", .double, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}

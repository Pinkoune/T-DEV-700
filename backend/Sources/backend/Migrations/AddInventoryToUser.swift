import Fluent

struct AddInventoryToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("inventory", .array(of: .string), .required, .sql(.default("{}")))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("inventory")
            .update()
    }
}

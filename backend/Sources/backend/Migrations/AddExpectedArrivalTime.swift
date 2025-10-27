import Fluent

struct AddExpectedArrivalTime: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .field("expected_arrival_time", .string, .required, .sql(.default("09:00")))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users")
            .deleteField("expected_arrival_time")
            .update()
    }
}

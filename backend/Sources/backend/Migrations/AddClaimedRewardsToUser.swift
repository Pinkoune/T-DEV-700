import Fluent

struct AddClaimedRewardsToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("claimed_rewards", .array(of: .int), .required, .sql(.default("{}")))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("claimed_rewards")
            .update()
    }
}

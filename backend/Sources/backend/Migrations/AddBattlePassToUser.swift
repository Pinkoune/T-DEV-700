import Fluent

struct AddBattlePassToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("battle_pass_exp", .int, .required, .sql(.default(0)))
            .field("last_quest_gen_date", .date)
            .field("daily_quests", .array(of: .dictionary), .required, .sql(.default("{}")))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("battle_pass_exp")
            .deleteField("last_quest_gen_date")
            .deleteField("daily_quests")
            .update()
    }
}

import Foundation

struct QuestManager {
    static func checkDailyQuests(user: User) -> Bool {
        var hasChanges = false
        let calendar = Calendar.current
        let today = Date()
        
        if user.lastQuestGenDate == nil || !calendar.isDate(user.lastQuestGenDate!, inSameDayAs: today) {
            user.dailyQuests = generateDailyQuests()
            user.lastQuestGenDate = today
            hasChanges = true
        }
        
        if updateQuestProgress(user: user, type: "login", amount: 1) {
            hasChanges = true
        }
        
        return hasChanges
    }
    
    static func generateDailyQuests() -> [User.DailyQuest] {
        return [
            User.DailyQuest(
                id: UUID().uuidString,
                title: "Se connecter",
                type: "login",
                target: 1,
                progress: 0,
                reward: 50,
                isCompleted: false
            ),
            User.DailyQuest(
                id: UUID().uuidString,
                title: "Gagner 20 pts",
                type: "points",
                target: 20,
                progress: 0,
                reward: 150,
                isCompleted: false
            ),
            User.DailyQuest(
                id: UUID().uuidString,
                title: "Être à l'heure",
                type: "punctuality",
                target: 1,
                progress: 0,
                reward: 200,
                isCompleted: false
            )
        ]
    }
    
    static let battlePassRewards: [Int: String] = [
        1: "Café",
        3: "Petite Frite",
        5: "McFlurry",
        8: "Cheeseburger",
        10: "Big Mac",
        12: "Nuggets x6",
        15: "Menu Best Of",
        20: "Menu Maxi Best Of"
    ]

    @discardableResult
    static func updateQuestProgress(user: User, type: String, amount: Int) -> Bool {
        var hasChanges = false
        
        for i in 0..<user.dailyQuests.count {
            if user.dailyQuests[i].type == type && !user.dailyQuests[i].isCompleted {
                user.dailyQuests[i].progress += amount
                
                if user.dailyQuests[i].progress >= user.dailyQuests[i].target {
                    user.dailyQuests[i].progress = user.dailyQuests[i].target
                    user.dailyQuests[i].isCompleted = true
                    user.battlePassExp += user.dailyQuests[i].reward
                }
                hasChanges = true
            }
        }
        
        return hasChanges
    }
}

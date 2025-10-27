import Foundation

struct Team: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let memberCount: Int
    
    init(name: String, memberCount: Int = 0) {
        self.name = name
        self.memberCount = memberCount
    }
}

extension Team {
    static let sampleTeams = [
        Team(name: "Équipe Marketing", memberCount: 5),
        Team(name: "Équipe Développement", memberCount: 8),
        Team(name: "Équipe Design", memberCount: 3),
        Team(name: "Équipe Commercial", memberCount: 6),
        Team(name: "Équipe Support", memberCount: 4)
    ]
}

//
//  Team.swift MAJ
//  Frontend
//
//  David
//

import Foundation
import SwiftUI


struct Team: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let memberCount: Int
    let managerId: String
    let color: String
    let teamSize: String
    let isLargeTeam: Bool
    let isActive: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    var uiColor: Color {
        Color(hex: color) ?? .blue
    }
    
    var sizeIcon: String {
        switch memberCount {
        case 1:
            return "person.fill"
        case 2...5:
            return "person.2.fill"
        case 6...15:
            return "person.3.fill"
        default:
            return "person.3.sequence.fill"
        }
    }
    
    init(from response: TeamResponse) {
        self.id = response.id ?? UUID().uuidString
        self.name = response.name
        self.description = response.description
        self.memberCount = response.memberCount
        self.managerId = response.managerId
        self.color = response.color
        self.teamSize = response.teamSize
        self.isLargeTeam = response.isLargeTeam
        self.isActive = response.isActive
        self.createdAt = response.createdAt
        self.updatedAt = response.updatedAt
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        memberCount: Int = 0,
        managerId: String = "",
        color: String = "#007AFF",
        teamSize: String = "Solo",
        isLargeTeam: Bool = false,
        isActive: Bool = true,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.memberCount = memberCount
        self.managerId = managerId
        self.color = color
        self.teamSize = teamSize
        self.isLargeTeam = isLargeTeam
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


extension Team {
    static let sampleTeams = [
        Team(
            id: "1",
            name: "Équipe Marketing",
            description: "Équipe en charge du marketing digital",
            memberCount: 5,
            managerId: "manager-1",
            color: "#FF6B6B",
            teamSize: "Petite équipe",
            isLargeTeam: false,
            isActive: true
        ),
        Team(
            id: "2",
            name: "Équipe Développement",
            description: "Équipe de développement logiciel",
            memberCount: 8,
            managerId: "manager-2",
            color: "#4ECDC4",
            teamSize: "Équipe moyenne",
            isLargeTeam: false,
            isActive: true
        ),
        Team(
            id: "3",
            name: "Équipe Design",
            description: "Équipe UX/UI Design",
            memberCount: 3,
            managerId: "manager-3",
            color: "#45B7D1",
            teamSize: "Petite équipe",
            isLargeTeam: false,
            isActive: true
        ),
        Team(
            id: "4",
            name: "Équipe Commercial",
            description: "Équipe commerciale et ventes",
            memberCount: 6,
            managerId: "manager-4",
            color: "#96CEB4",
            teamSize: "Équipe moyenne",
            isLargeTeam: false,
            isActive: true
        ),
        Team(
            id: "5",
            name: "Équipe Support",
            description: "Support client et technique",
            memberCount: 4,
            managerId: "manager-5",
            color: "#FFEAA7",
            teamSize: "Petite équipe",
            isLargeTeam: false,
            isActive: true
        )
    ]
}


extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}


struct TeamColors {
    static let available: [(name: String, hex: String)] = [
        ("Rouge", "#FF6B6B"),
        ("Vert", "#4ECDC4"),
        ("Bleu", "#45B7D1"),
        ("Jaune", "#FFEAA7"),
        ("Violet", "#A29BFE"),
        ("Orange", "#FD9644"),
        ("Rose", "#FD79A8"),
        ("Turquoise", "#00CEC9"),
        ("Indigo", "#6C5CE7"),
        ("Vert menthe", "#96CEB4")
    ]
    
    static func color(for hex: String) -> Color {
        Color(hex: hex) ?? .blue
    }
}

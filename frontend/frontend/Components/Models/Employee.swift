import Foundation

struct Employee: Identifiable, Hashable {
    let id = UUID()
    let firstName: String
    let lastName: String
    let role: String
    let teamId: UUID? // Pour lier l'employé à une équipe
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    init(firstName: String, lastName: String, role: String, teamId: UUID? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.teamId = teamId
    }
}

extension Employee {
    static let sampleEmployees = [
        // Équipe Marketing
        Employee(firstName: "Marie", lastName: "Dupont", role: "Responsable Marketing"),
        Employee(firstName: "Thomas", lastName: "Martin", role: "Chargé de communication"),
        Employee(firstName: "Sophie", lastName: "Bernard", role: "Social Media Manager"),
        Employee(firstName: "Lucas", lastName: "Petit", role: "Content Creator"),
        Employee(firstName: "Emma", lastName: "Durand", role: "Analyste Marketing"),
        
        // Équipe Développement
        Employee(firstName: "Alexandre", lastName: "Moreau", role: "Lead Developer"),
        Employee(firstName: "Julie", lastName: "Simon", role: "Full Stack Developer"),
        Employee(firstName: "Nicolas", lastName: "Laurent", role: "Frontend Developer"),
        Employee(firstName: "Camille", lastName: "Lefebvre", role: "Backend Developer"),
        Employee(firstName: "Hugo", lastName: "Roux", role: "DevOps Engineer"),
        Employee(firstName: "Léa", lastName: "Garnier", role: "iOS Developer"),
        Employee(firstName: "Antoine", lastName: "Faure", role: "Android Developer"),
        Employee(firstName: "Clara", lastName: "Girard", role: "QA Engineer"),
        
        // Équipe Design
        Employee(firstName: "Élise", lastName: "Mercier", role: "UI/UX Designer"),
        Employee(firstName: "Maxime", lastName: "Blanc", role: "Product Designer"),
        Employee(firstName: "Chloé", lastName: "Martinez", role: "Graphic Designer")
    ]
}

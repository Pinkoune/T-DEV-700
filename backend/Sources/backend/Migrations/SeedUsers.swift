import Fluent
import Vapor

struct SeedUsers: AsyncMigration {
    func prepare(on database: Database) async throws {
        let passwords = [
            try Bcrypt.hash("Admin2024!"),
            try Bcrypt.hash("Manager123!"),
            try Bcrypt.hash("Employee2024!"),
            try Bcrypt.hash("Secure123!"),
            try Bcrypt.hash("Welcome2024!")
        ]
        
        let admin = User(
            firstName: "Admin",
            lastName: "System",
            email: "admin@company.com",
            passwordHash: passwords[0],
            phone: "0601000000",
            role: "admin",
            department: "Direction",
            position: "Administrateur Système"
        )
        try await admin.save(on: database)
        
        let managerNames = [
            ("Sophie", "Dubois", "IT", "Chef de Projet IT"),
            ("Marc", "Bernard", "RH", "Responsable RH"),
            ("Julie", "Petit", "Marketing", "Directrice Marketing"),
            ("Pierre", "Durand", "Ventes", "Directeur Commercial"),
            ("Marie", "Lefevre", "Finance", "Directrice Financière"),
            ("Nicolas", "Moreau", "IT", "Lead Developer"),
            ("Isabelle", "Laurent", "RH", "Responsable Formation"),
            ("François", "Simon", "Marketing", "Chef de Produit"),
            ("Catherine", "Michel", "Ventes", "Manager Ventes"),
            ("Philippe", "Garcia", "Finance", "Contrôleur de Gestion"),
            ("Nathalie", "Martinez", "IT", "Architecte Système"),
            ("Olivier", "Rodriguez", "RH", "Responsable Recrutement"),
            ("Sylvie", "Hernandez", "Marketing", "Responsable Communication"),
            ("Christophe", "Lopez", "Ventes", "Manager Grands Comptes"),
            ("Valérie", "Gonzalez", "Finance", "Responsable Comptabilité")
        ]
        
        for (index, manager) in managerNames.enumerated() {
            let user = User(
                firstName: manager.0,
                lastName: manager.1,
                email: "\(manager.0.lowercased()).\(manager.1.lowercased())@company.com",
                passwordHash: passwords[1],
                phone: String(format: "06%08d", 1000001 + index),
                role: "manager",
                department: manager.2,
                position: manager.3
            )
            try await user.save(on: database)
        }
        
        let firstNames = ["Thomas", "Emma", "Lucas", "Léa", "Hugo", "Chloé", "Nathan", "Sarah", "Antoine", "Camille",
                         "Alexandre", "Laura", "Maxime", "Manon", "Louis", "Clara", "Gabriel", "Jade", "Arthur", "Zoé",
                         "Paul", "Alice", "Raphaël", "Inès", "Adam", "Lola", "Tom", "Mila", "Théo", "Rose",
                         "Jules", "Anna", "Ethan", "Lina", "Noah", "Lou", "Mathis", "Léna", "Clément", "Juliette",
                         "Baptiste", "Romane", "Victor", "Eva", "Enzo", "Margaux", "Mathéo", "Lucie", "Maxence", "Charlotte"]
        
        let lastNames = ["Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau",
                        "Simon", "Laurent", "Lefebvre", "Michel", "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier",
                        "Morel", "Girard", "Andre", "Lefevre", "Mercier", "Dupont", "Lambert", "Bonnet", "Francois", "Martinez",
                        "Legrand", "Garnier", "Faure", "Rousseau", "Blanc", "Guerin", "Muller", "Henry", "Roussel", "Nicolas",
                        "Perrin", "Morin", "Mathieu", "Clement", "Gauthier", "Dumont", "Lopez", "Fontaine", "Chevalier", "Robin"]
        
        let departments = ["IT", "RH", "Marketing", "Ventes", "Finance", "Support", "Production", "Logistique"]
        
        let positions = [
            "IT": ["Développeur Full Stack", "Développeur Frontend", "Développeur Backend", "DevOps Engineer", "Data Scientist", "Analyste Système", "Technicien Support"],
            "RH": ["Chargé de Recrutement", "Gestionnaire de Paie", "Assistant RH", "Responsable Formation", "Chargé de Mobilité"],
            "Marketing": ["Community Manager", "Content Manager", "SEO Specialist", "Traffic Manager", "Chef de Projet Digital", "Graphiste"],
            "Ventes": ["Commercial", "Technico-Commercial", "Account Manager", "Business Developer", "Chargé d'Affaires"],
            "Finance": ["Comptable", "Contrôleur de Gestion", "Analyste Financier", "Assistant Comptable", "Trésorier"],
            "Support": ["Support Client", "Technicien Helpdesk", "Responsable Support", "Chargé de Clientèle"],
            "Production": ["Chef de Production", "Technicien de Production", "Opérateur", "Contrôleur Qualité"],
            "Logistique": ["Responsable Logistique", "Préparateur de Commandes", "Gestionnaire de Stock", "Agent Logistique"]
        ]
        
        var employeeCount = 0
        for i in 0..<84 {
            let firstName = firstNames[i % firstNames.count]
            let lastName = lastNames[i % lastNames.count]
            let department = departments[i % departments.count]
            let positionList = positions[department] ?? ["Employé"]
            let position = positionList[i % positionList.count]
            
            let user = User(
                firstName: firstName,
                lastName: lastName,
                email: "\(firstName.lowercased()).\(lastName.lowercased())\(i)@company.com",
                passwordHash: passwords[2 + (i % 3)],
                phone: String(format: "06%08d", 2000001 + i),
                role: "employee",
                department: department,
                position: position
            )
            try await user.save(on: database)
            employeeCount += 1
        }
        
        print("✅ Seed terminé : 1 admin + 15 managers + \(employeeCount) employés = \(1 + 15 + employeeCount) utilisateurs")
    }

    func revert(on database: Database) async throws {
        try await User.query(on: database)
            .filter(\.$email ~~ "@company.com")
            .delete()
    }
}
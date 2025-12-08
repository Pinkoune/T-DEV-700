//
//  TeamMember.swift
//  Frontend
//
//  David
//

import Foundation

/// Modèle TeamMember pour l'affichage des membres d'équipe

struct TeamMember: Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let fullName: String
    let email: String
    let phone: String
    let role: String
    let displayRole: String
    let department: String?
    let position: String?
    let weeklyHoursTarget: Double
    let isActive: Bool
    let hireDate: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    

    var isManager: Bool {
        role == "manager"
    }
    
    var yearsOfService: Int? {
        guard let hireDate = hireDate else { return nil }
        return Calendar.current.dateComponents([.year], from: hireDate, to: Date()).year
    }
    
    /// Initialisation depuis TeamMemberResponse
    init(from response: TeamMemberResponse) {
        self.id = response.id ?? UUID().uuidString
        self.firstName = response.firstName
        self.lastName = response.lastName
        self.fullName = response.fullName
        self.email = response.email
        self.phone = response.phone
        self.role = response.role
        self.displayRole = response.displayRole
        self.department = response.department
        self.position = response.position
        self.weeklyHoursTarget = response.weeklyHoursTarget
        self.isActive = response.isActive
        self.hireDate = response.hireDate
        self.createdAt = response.createdAt
        self.updatedAt = response.updatedAt
    }
    
    /// Initialisation manuelle
    init(
        id: String = UUID().uuidString,
        firstName: String,
        lastName: String,
        email: String = "",
        phone: String = "",
        role: String = "employee",
        department: String? = nil,
        position: String? = nil,
        weeklyHoursTarget: Double = 35.0,
        isActive: Bool = true,
        hireDate: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = "\(firstName) \(lastName)"
        self.email = email
        self.phone = phone
        self.role = role
        self.displayRole = role == "manager" ? "Manager" : "Employé"
        self.department = department
        self.position = position
        self.weeklyHoursTarget = weeklyHoursTarget
        self.isActive = isActive
        self.hireDate = hireDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Mock Data (pour les previews)

extension TeamMember {
    static let sampleMembers = [
        TeamMember(
            id: "1",
            firstName: "Marie",
            lastName: "Dupont",
            email: "marie.dupont@company.com",
            phone: "0612345678",
            role: "manager",
            department: "Marketing",
            position: "Responsable Marketing"
        ),
        TeamMember(
            id: "2",
            firstName: "Thomas",
            lastName: "Martin",
            email: "thomas.martin@company.com",
            phone: "0623456789",
            role: "employee",
            department: "Marketing",
            position: "Chargé de communication"
        ),
        TeamMember(
            id: "3",
            firstName: "Sophie",
            lastName: "Bernard",
            email: "sophie.bernard@company.com",
            phone: "0634567890",
            role: "employee",
            department: "Marketing",
            position: "Social Media Manager"
        ),
        TeamMember(
            id: "4",
            firstName: "Lucas",
            lastName: "Petit",
            email: "lucas.petit@company.com",
            phone: "0645678901",
            role: "employee",
            department: "Marketing",
            position: "Content Creator"
        ),
        TeamMember(
            id: "5",
            firstName: "Emma",
            lastName: "Durand",
            email: "emma.durand@company.com",
            phone: "0656789012",
            role: "employee",
            department: "Marketing",
            position: "Analyste Marketing"
        )
    ]
}


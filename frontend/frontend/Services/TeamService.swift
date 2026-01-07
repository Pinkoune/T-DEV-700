//
//  TeamService.swift
//  Frontend
//
//  David
//

import Foundation

class TeamService {
    static let baseURL = "\(Config.baseURL)/teams"
    
    // MARK: - Get All Teams
    
    static func getAllTeams() async throws -> [TeamResponse] {
        guard let url = URL(string: baseURL) else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la récupération des équipes")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TeamResponse].self, from: data)
    }
    
    // MARK: - Get Team by ID
    
    static func getTeam(id: String) async throws -> TeamDetailResponse {
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.notFound
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TeamDetailResponse.self, from: data)
    }
    
    // MARK: - Get Teams by Manager
    
    static func getTeamsByManager(managerId: String) async throws -> [TeamResponse] {
        guard let url = URL(string: "\(baseURL)/by-manager/\(managerId)") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la récupération des équipes")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TeamResponse].self, from: data)
    }
    
    // MARK: - Create Team
    
    static func createTeam(name: String, description: String, managerId: String, color: String?) async throws -> TeamResponse {
        guard let url = URL(string: baseURL) else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let createData = CreateTeamRequest(
            name: name,
            description: description,
            managerId: managerId,
            color: color
        )
        request.httpBody = try JSONEncoder().encode(createData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la création de l'équipe")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TeamResponse.self, from: data)
    }
    
    // MARK: - Update Team
    
    static func updateTeam(id: String, name: String?, description: String?, managerId: String?, color: String?, isActive: Bool?) async throws -> TeamResponse {
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let updateData = UpdateTeamRequest(
            name: name,
            description: description,
            managerId: managerId,
            color: color,
            isActive: isActive
        )
        request.httpBody = try JSONEncoder().encode(updateData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la mise à jour de l'équipe")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TeamResponse.self, from: data)
    }
    
    // MARK: - Delete Team
    
    static func deleteTeam(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 204 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la suppression de l'équipe")
        }
    }
    
    // MARK: - Get Team Members
    
    static func getTeamMembers(teamId: String) async throws -> [TeamMemberResponse] {
        guard let url = URL(string: "\(baseURL)/\(teamId)/members") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la récupération des membres")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TeamMemberResponse].self, from: data)
    }
    
    // MARK: - Add Member to Team
    
    static func addMember(teamId: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/\(teamId)/members/\(userId)") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 201 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de l'ajout du membre")
        }
    }
    
    // MARK: - Remove Member from Team
    
    static func removeMember(teamId: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/\(teamId)/members/\(userId)") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 204 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la suppression du membre")
        }
    }
    
    // MARK: - Get Team Stats
    
    static func getTeamStats(teamId: String) async throws -> TeamStatsResponse {
        guard let url = URL(string: "\(baseURL)/\(teamId)/stats") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la récupération des statistiques")
        }
        
        return try JSONDecoder().decode(TeamStatsResponse.self, from: data)
    }
    
    // MARK: - Get Team Performance
    
    static func getTeamPerformance(teamId: String) async throws -> [TeamMemberPerformance] {
        guard let url = URL(string: "\(baseURL)/\(teamId)/performance") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la récupération des performances")
        }
        
        return try JSONDecoder().decode([TeamMemberPerformance].self, from: data)
    }
    
    // MARK: - Search Teams
    
    static func searchTeams(query: String) async throws -> [TeamResponse] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la recherche")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TeamResponse].self, from: data)
    }
    
    // MARK: - Get Active Teams
    
    static func getActiveTeams() async throws -> [TeamResponse] {
        guard let url = URL(string: "\(baseURL)/active") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la récupération des équipes actives")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TeamResponse].self, from: data)
    }
    
    // MARK: - Get All Users (for adding members)
    
    static func getAllUsers() async throws -> [TeamMemberResponse] {
        guard let url = URL(string: "\(Config.baseURL)/users") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la récupération des utilisateurs")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TeamMemberResponse].self, from: data)
    }
    
    // MARK: - Get Member Stats
    
    static func getMemberStats(teamId: String, userId: String) async throws -> TeamMemberStatsResponse {
        guard let url = URL(string: "\(baseURL)/\(teamId)/members/\(userId)/stats") else {
            throw TeamError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw TeamError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TeamError.serverError(errorResponse.reason ?? "Erreur serveur")
            }
            throw TeamError.serverError("Erreur lors de la récupération des stats membre")
        }
        
        return try JSONDecoder().decode(TeamMemberStatsResponse.self, from: data)
    }
}

// MARK: - Request Models

struct CreateTeamRequest: Codable {
    let name: String
    let description: String
    let managerId: String
    let color: String?
}

struct UpdateTeamRequest: Codable {
    let name: String?
    let description: String?
    let managerId: String?
    let color: String?
    let isActive: Bool?
}

// MARK: - Response Models

struct TeamResponse: Codable, Identifiable, Hashable {
    let id: String?
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TeamResponse, rhs: TeamResponse) -> Bool {
        lhs.id == rhs.id
    }
}

struct TeamDetailResponse: Codable {
    let team: TeamResponse
    let members: [TeamMemberResponse]
    let manager: TeamMemberResponse?
}

struct TeamMemberResponse: Codable, Identifiable, Hashable {
    let id: String?
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TeamMemberResponse, rhs: TeamMemberResponse) -> Bool {
        lhs.id == rhs.id
    }
}

struct TeamStatsResponse: Codable {
    let teamId: String
    let totalMembers: Int
    let activeTimeEntries: Int
    let averagePerformance: Double
    let teamSize: String
    let isLargeTeam: Bool
    let latenessRate: Double
    let totalLateEntries: Int
    let averageLateMinutes: Double
}

struct TeamMemberStatsResponse: Codable {
    let userId: String
    let averageWeeklyHours: Double
    let latenessCount: Int
    let taskCompletionRate: Double
}

struct TeamMemberPerformance: Codable, Identifiable {
    let userId: String
    let userName: String
    let isManager: Bool
    let latestPerformance: Double?
    let performanceLevel: String
    
    var id: String { userId }
}

// MARK: - Error Handling

enum TeamError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .unauthorized:
            return "Non autorisé - veuillez vous reconnecter"
        case .notFound:
            return "Équipe non trouvée"
        case .serverError(let message):
            return message
        case .networkError:
            return "Problème de connexion au serveur"
        }
    }
}


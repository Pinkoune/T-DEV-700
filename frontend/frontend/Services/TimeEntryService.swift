//
//  TimeEntryService.swift
//  frontend
//
//  Created by Mathieu Exposito on 23/10/2025.
//

import Foundation

class TimeEntryService {
    static let baseURL = Config.baseURL
    
    
    static func clock(userId: String) async throws -> TimeEntryResponse {
        guard let url = URL(string: "\(baseURL)/clocks") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw AuthError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let clockData = ClockRequest(userId: userId)
        request.httpBody = try JSONEncoder().encode(clockData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorResponse.reason ?? "Erreur avec le serveur")
            }
            throw AuthError.serverError("Erreur lors du pointage")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let timeEntry = try decoder.decode(TimeEntryResponse.self, from: data)
        return timeEntry
    }
    
    static func getActiveTimeEntry(userId: String) async throws -> ActiveTimeEntryResponse {
        guard let url = URL(string: "\(baseURL)/timeentries/active/\(userId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw AuthError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw AuthError.serverError("Erreur lors de la récupération des données")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activeEntry = try decoder.decode(ActiveTimeEntryResponse.self, from: data)
        return activeEntry
    }
    
    static func getTimeEntries(userId: String, limit: Int = 10) async throws -> [TimeEntryResponse] {
        guard let url = URL(string: "\(baseURL)/timeentries/by-user/\(userId)?limit=\(limit)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw AuthError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw AuthError.serverError("Erreur lors de la récupération de l'historique")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([TimeEntryResponse].self, from: data)
        return entries
    }
}

struct ClockRequest: Codable {
    let userId: String
}

struct TimeEntryResponse: Codable {
    let id: String?
    let userId: String
    let userName: String
    let arrival: Date
    let departure: Date?
    let hoursWorked: Double?
    let status: String
    let notes: String?
    let isOvertime: Bool
    let overtimeHours: Double
    let createdAt: Date?
}

struct ActiveTimeEntryResponse: Codable {
    let hasActiveEntry: Bool
    let timeEntry: TimeEntryResponse?
}

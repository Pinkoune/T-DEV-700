//
//  AuthService.swift
//  frontend
//
//  Created by Mathieu Exposito on 13/10/2025.
//

import Foundation

class AuthService {
    static let baseURL = "\(Config.baseURL)/auth"
    
    static func login(email: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/login") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let loginData = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(loginData)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.networkError
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorResponse.reason ?? "Erreur du serveur")
            }
            throw AuthError.unauthorized
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        UserDefaults.standard.set(loginResponse.token, forKey: "authToken")
        UserDefaults.standard.set(loginResponse.user.id, forKey: "userId")
        
        return loginResponse
    }
    
    static func logout() async throws {
        guard let token = getToken() else {
            clearLocalData()
            return
        }
        
        guard let url = URL(string: "\(baseURL)/logout") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                clearLocalData()
            } else {
                clearLocalData()
            }
        } catch {
            clearLocalData()
            throw AuthError.networkError
        }
    }
    
    static func clearLocalData() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userFirstName")
        UserDefaults.standard.removeObject(forKey: "userLastName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
    
    static func isLoggedIn() -> Bool {
        return UserDefaults.standard.string(forKey: "authToken") != nil
    }
    
    static func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    static func refreshToken() async throws -> LoginResponse {
        guard let currentToken = getToken() else {
            throw AuthError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/refresh") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let refreshData = RefreshRequest(token: currentToken)
        request.httpBody = try JSONEncoder().encode(refreshData)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.networkError
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorResponse.reason ?? "Erreur du serveur")
            }
            throw AuthError.unauthorized
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        UserDefaults.standard.set(loginResponse.token, forKey: "authToken")
        UserDefaults.standard.set(loginResponse.user.id, forKey: "userId")
        
        return loginResponse
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RefreshRequest: Codable {
    let token: String
}

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let token: String
    let user: User
}

struct User: Codable {
    let id: String?
    let firstName: String
    let lastName: String
    let fullName: String
    let email: String
    let role: String
    let department: String?
    let position: String?
}

struct ErrorResponse: Codable {
    let error: Bool
    let reason: String?
}

enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .unauthorized:
            return "Email ou mot de passe incorrect"
        case .serverError(let message):
            return message
        case .networkError:
            return "Problème de connexion au serveur"
        }
    }
}
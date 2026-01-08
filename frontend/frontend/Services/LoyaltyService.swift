import Foundation

class LoyaltyService {
    static let baseURL = "\(Config.baseURL)/users"
    
    static func addPoints(userId: String, points: Int) async throws -> User {
        guard let url = URL(string: "\(baseURL)/\(userId)/loyalty/add") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw AuthError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["points": points]
        request.httpBody = try JSONEncoder().encode(body)
        
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
        
        
        // Backend returns UserResponse, which matches structure of User in AuthService approximately
        // We decode directly to User
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    static func buyReward(userId: String, item: String, cost: Int) async throws -> User {
        guard let url = URL(string: "\(baseURL)/\(userId)/loyalty/buy") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw AuthError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = BuyRewardRequest(item: item, cost: cost)
        request.httpBody = try JSONEncoder().encode(body)
        
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
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    static func useReward(userId: String, item: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/\(userId)/loyalty/use") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw AuthError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["item": item]
        request.httpBody = try JSONEncoder().encode(body)
        
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
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    static func claimReward(userId: String, level: Int) async throws -> User {
        guard let url = URL(string: "\(baseURL)/\(userId)/loyalty/claim") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw AuthError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ClaimRewardRequest(level: level)
        request.httpBody = try JSONEncoder().encode(body)
        
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
        
        return try JSONDecoder().decode(User.self, from: data)
    }
}

struct BuyRewardRequest: Codable {
    let item: String
    let cost: Int
}

struct UseRewardRequest: Codable {
    let item: String
}

struct ClaimRewardRequest: Codable {
    let level: Int
}

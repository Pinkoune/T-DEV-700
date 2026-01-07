import Foundation

class UserService {
    static let baseURL = "\(Config.baseURL)/auth"
    
    static func updateProfile(firstName: String, lastName: String, email: String) async throws -> UpdateProfileResponse {
        guard let url = URL(string: "\(baseURL)/update-profile") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.getToken() else {
            throw AuthError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let updateData = UpdateProfileRequest(
            firstName: firstName,
            lastName: lastName,
            email: email
        )
        request.httpBody = try JSONEncoder().encode(updateData)
        
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
        
        let updateResponse = try JSONDecoder().decode(UpdateProfileResponse.self, from: data)
        
        UserDefaults.standard.set(updateResponse.user.firstName, forKey: "userFirstName")
        UserDefaults.standard.set(updateResponse.user.lastName, forKey: "userLastName")
        UserDefaults.standard.set(updateResponse.user.email, forKey: "userEmail")
        
        return updateResponse
    }
}

struct UpdateProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
}

struct UpdateProfileResponse: Codable {
    let success: Bool
    let message: String
    let user: User
}

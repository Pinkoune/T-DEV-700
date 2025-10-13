import Vapor
import FirebaseFirestore
import FirebaseFirestoreSwift

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("api", "auth")
        
        auth.post("login", use: login)
    }
    
    /// POST /api/auth/login - Connexion d'un utilisateur
    func login(req: Request) async throws -> LoginResponse {
        let loginData = try req.content.decode(LoginRequest.self)
        
        guard isValidPassword(loginData.password) else {
            throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("users")
                .whereField("email", isEqualTo: loginData.email)
                .whereField("isActive", isEqualTo: true)
                .limit(to: 1)
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                throw Abort(.unauthorized, reason: "Email ou mot de passe incorrect")
            }
            
            guard var user = try? document.data(as: User.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'utilisateur")
            }
            
            user.id = document.documentID
            
            let isPasswordValid = try req.password.verify(loginData.password, created: user.passwordHash)
            
            guard isPasswordValid else {
                throw Abort(.unauthorized, reason: "Email ou mot de passe incorrect")
            }
            
            // Token à revoir plus tard avec JWT
            let token = UUID().uuidString
            
            return LoginResponse(
                success: true,
                message: "Connexion réussie",
                token: token,
                user: UserResponse(from: user)
            )
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la connexion: \(error.localizedDescription)")
        }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let uppercaseRegex = ".*[A-Z]+.*"
        guard password.range(of: uppercaseRegex, options: .regularExpression) != nil else { return false }
        
        let digitRegex = ".*[0-9]+.*"
        guard password.range(of: digitRegex, options: .regularExpression) != nil else { return false }
        
        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
        guard password.range(of: specialCharRegex, options: .regularExpression) != nil else { return false }
        
        return true
    }
}

struct LoginRequest: Content {
    let email: String
    let password: String
}

struct LoginResponse: Content {
    let success: Bool
    let message: String
    let token: String
    let user: UserResponse
}

struct UserResponse: Content {
    let id: String?
    let firstName: String
    let lastName: String
    let fullName: String
    let email: String
    let role: String
    let department: String?
    let position: String?
    
    init(from user: User) {
        self.id = user.id
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.fullName = user.fullName
        self.email = user.email
        self.role = user.role
        self.department = user.department
        self.position = user.position
    }
}

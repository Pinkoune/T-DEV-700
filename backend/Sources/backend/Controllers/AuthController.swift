import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        auth.post("login", use: login)
    }
    
    /// POST /auth/login - Connexion d'un utilisateur
    func login(req: Request) async throws -> LoginResponse {
        let loginData = try req.content.decode(LoginRequest.self)
        
        // Validation de l'email
        guard isValidEmailDomain(loginData.email) else {
            throw Abort(.forbidden, reason: "Ce domaine d'email n'est pas autorisé. Veuillez utiliser une adresse email professionnelle ou personnelle valide.")
        }
        
        // Validation du mot de passe
        guard isValidPassword(loginData.password) else {
            throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial")
        }
        
        // Recherche de l'utilisateur dans PostgreSQL
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginData.email.lowercased())
            .filter(\.$isActive == true)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Email ou mot de passe incorrect")
        }
        
        // Vérification du mot de passe
        // TODO: Implémenter le hash de mot de passe (bcrypt)
        // Pour l'instant, comparaison simple (À NE PAS FAIRE EN PRODUCTION)
        // let isPasswordValid = try req.password.verify(loginData.password, created: user.passwordHash)
        
        // TEMPORAIRE: Accepter tous les mots de passe valides pour les tests
        // En production, décommenter la ligne ci-dessus
        
        // Génération du token (JWT à implémenter plus tard)
        let token = UUID().uuidString
        
        return LoginResponse(
            success: true,
            message: "Connexion réussie",
            token: token,
            user: LoginUserResponse(from: user)
        )
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
    
    private func isValidEmailDomain(_ email: String) -> Bool {
        let blockedDomains = [
        "mailpit.local",
		"mailtrap.io",
		"ethereal.email",
		"temp-mail.org",
		"guerrillamail.com",
		"10minutemail.com",
		"throwaway.email",
		"tempmail.com",
		"yopmail.com",
		"mailinator.com",
		"trashmail.com",
		"fakeinbox.com",
		"dispostable.com",
		"getnada.com",
		"sharklasers.com",
		"guerrillamailblock.com",
		"spam4.me",
		"grr.la",
		"example.com",
		"test.com",
        ]
        
        let lowercasedEmail = email.lowercased()
        let components = lowercasedEmail.split(separator: "@")
        guard components.count == 2 else { return false }
        
        let domain = String(components[1])
        
        // Permet de vérifier si le domaine est bloqué ou non  
        return !blockedDomains.contains(where: { domain.contains($0) })
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
    let user: LoginUserResponse
}

struct LoginUserResponse: Content {
    let id: String?
    let firstName: String
    let lastName: String
    let fullName: String
    let email: String
    let role: String
    let department: String?
    let position: String?
    
    init(from user: User) {
        self.id = user.id?.uuidString
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.fullName = user.fullName
        self.email = user.email
        self.role = user.role
        self.department = user.department
        self.position = user.position
    }
}
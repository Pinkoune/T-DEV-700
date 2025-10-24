import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        auth.post("login", use: login)
        auth.post("register", use: register)
        auth.post("refresh", use: refresh)
        
        let protected = auth.grouped(JWTAuthMiddleware())
        protected.post("logout", use: logout)
    }
    
    /// POST /auth/login - Connexion d'un utilisateur
    func login(req: Request) async throws -> LoginResponse {
        let loginData = try req.content.decode(LoginRequest.self)
        
        guard isValidEmailDomain(loginData.email) else {
            throw Abort(.forbidden, reason: "Ce domaine d'email n'est pas autorisé. Veuillez utiliser une adresse email professionnelle ou personnelle valide.")
        }
        
        guard isValidPassword(loginData.password) else {
            throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial")
        }
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginData.email.lowercased())
            .filter(\.$isActive == true)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Email ou mot de passe incorrect")
        }

        let isPasswordValid = try req.password.verify(loginData.password, created: user.passwordHash)

        if !isPasswordValid {
            throw Abort(.unauthorized, reason: "Email ou mot de passe incorrect")
        }

        let payload = UserJWTPayload(
            userId: user.id!.uuidString,
            email: user.email,
            role: user.role,
            exp: .init(value: Date().addingTimeInterval(86400))
        )

        let token = try req.jwt.sign(payload)

        return LoginResponse(
            success: true,
            message: "Connexion réussie",
            token: token,
            user: LoginUserResponse(from: user)
        )
    }


    /// POST /auth/refresh - Rafraîchissement du token
    func refresh(req: Request) async throws -> LoginResponse {
        let refreshData = try req.content.decode(RefreshRequest.self)
        
        req.logger.info("[AUTH] Tentative de rafraîchissement de token")
        
        let payload: UserJWTPayload
        do {
            payload = try req.jwt.verify(refreshData.token, as: UserJWTPayload.self)
        } catch {
            req.logger.warning("[AUTH] Token invalide ou expiré pour rafraîchissement")
            throw Abort(.unauthorized, reason: "Token invalide ou expiré")
        }
        
        guard let userId = UUID(uuidString: payload.userId) else {
            req.logger.warning("[AUTH] User ID invalide dans le token")
            throw Abort(.unauthorized, reason: "Token invalide")
        }
        
        guard let user = try await User.find(userId, on: req.db) else {
            req.logger.warning("[AUTH] Utilisateur introuvable pour rafraîchissement: \(payload.userId)")
            throw Abort(.unauthorized, reason: "Utilisateur non trouvé")
        }
        
        guard user.isActive else {
            req.logger.warning("[AUTH] Compte inactif pour rafraîchissement: \(user.email)")
            throw Abort(.unauthorized, reason: "Compte désactivé")
        }
        
        let newPayload = UserJWTPayload(
            userId: user.id!.uuidString,
            email: user.email,
            role: user.role,
            exp: .init(value: Date().addingTimeInterval(86400))
        )
        
        let newToken = try req.jwt.sign(newPayload)
        
        req.logger.info("[AUTH] Token rafraîchi avec succès - Email: \(user.email), ID: \(user.id?.uuidString ?? "N/A")")
        
        return LoginResponse(
            success: true,
            message: "Token rafraîchi avec succès",
            token: newToken,
            user: LoginUserResponse(from: user)
        )
    }
    
    /// POST /auth/logout - Déconnexion de l'utilisateur
    func logout(req: Request) async throws -> LogoutResponse {
        let user = try req.auth.require(User.self)
        
        req.logger.info("[AUTH] Déconnexion - Email: \(user.email), ID: \(user.id?.uuidString ?? "N/A")")
        
    
        return LogoutResponse(
            success: true,
            message: "Déconnexion réussie"
        )
    }

    /// POST /auth/register - Inscription d'un nouvel utilisateur
    func register(req: Request) async throws -> LoginResponse {
        let registerData = try req.content.decode(RegisterRequest.self)

        guard isValidEmailDomain(registerData.email) else {
            throw Abort(.forbidden, reason: "Ce domaine d'email n'est pas autorisé")
        }

        guard isValidPassword(registerData.password) else {
            throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial")
        }

        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == registerData.email.lowercased())
            .first()

        if existingUser != nil {
            throw Abort(.conflict, reason: "Cet email est déjà utilisé")
        }

        let passwordHash = try req.password.hash(registerData.password)

        let user = User(
            firstName: registerData.firstName,
            lastName: registerData.lastName,
            email: registerData.email.lowercased(),
            passwordHash: passwordHash,
            phone: registerData.phone,
            role: "employee",
            department: registerData.department,
            position: registerData.position
        )

        try await user.save(on: req.db)

        let payload = UserJWTPayload(
            userId: user.id!.uuidString,
            email: user.email,
            role: user.role,
            exp: .init(value: Date().addingTimeInterval(86400))
        )

        let token = try req.jwt.sign(payload)

        return LoginResponse(
            success: true,
            message: "Inscription réussie",
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

struct RegisterRequest: Content {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let phone: String
    let department: String?
    let position: String?
}

struct LoginResponse: Content {
    let success: Bool
    let message: String
    let token: String
    let user: LoginUserResponse
}

struct RefreshRequest: Content {
    let token: String
}

struct LogoutResponse: Content {
    let success: Bool
    let message: String
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
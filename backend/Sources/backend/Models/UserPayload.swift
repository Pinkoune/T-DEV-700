import JWT
import Vapor

struct UserPayload: JWTPayload, Authenticatable {
    // Claims essentiels
    var sub: SubjectClaim          // User ID
    var exp: ExpirationClaim       // Expiration
    var iat: IssuedAtClaim         // Émis à
    
    // Claims personnalisés
    var userId: String
    var email: String
    var role: String
    var permissions: [String]
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
        
        // Validations personnalisées
        guard !userId.isEmpty else {
            throw JWTError.claimVerificationFailure(name: "userId", reason: "User ID requis")
        }
        
        let validRoles = ["admin", "manager", "employee"]
        guard validRoles.contains(role) else {
            throw JWTError.claimVerificationFailure(name: "role", reason: "Rôle invalide")
        }
    }
    
    init(user: User) {
        let now = Date()
        
        self.sub = SubjectClaim(value: user.id ?? UUID().uuidString)
        self.exp = ExpirationClaim(value: now.addingTimeInterval(3600)) // 1 heure
        self.iat = IssuedAtClaim(value: now)
        
        self.userId = user.id ?? ""
        self.email = user.email
        self.role = user.role
        self.permissions = Self.getUserPermissions(for: user.role)
    }
    
    private static func getUserPermissions(for role: String) -> [String] {
        switch role {
        case "admin":
            return ["read:all", "write:all", "delete:all", "manage:users"]
        case "manager":
            return ["read:team", "write:team", "manage:timeentries"]
        case "employee":
            return ["read:own", "write:own"]
        default:
            return ["read:own"]
        }
    }
}


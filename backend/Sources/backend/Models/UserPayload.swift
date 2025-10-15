import JWT

struct UserPayload: JWTPayload {
    // Standards Claims qui utilise les types fournis pour une validation facile
    var sub: SubjectClaim // "sub" : ID ou sujet de l'utilisateur
    var exp: ExpirationClaim // "exp" : Expiration (obligatoire pour la sécurité)
    var iat: IssuedAtClaim? // "iat" : Date d'émission
    var iss: IssuerClaim? // "iss" : Émetteur (url en https)
    var aud: AudienceClaim? // "aud" : Audience (app mobile, app web, etc)

    // Custom Claims
    var userId: UUID // ID utilisateur custom encodé en string
    var roles: [String] // Tableau de rôles
    var isVerified: Bool // Flag booléen custom

    // CodingKeys pour mapper les propriétés aux clés JSON
    enum CodingKeys: String, CodingKey {
        case sub
        case exp
        case iat
        case iss
        case aud
        case userId = "uid" // Mappe "uid" dans le JSON
        case roles
        case isVerified = "verified"
    }

    // Méthode de vérification obligatoire
    func verify(using algorithm: some JWTAlgorithm) async throws {
        // Vérifications standards
        try self.exp.verifyNotExpired() // Throw si expiré
        if let iat = self.iat {
            try iat.verifyIssuedInThePast() // Vérifie que "iat" est dans le passé
        }
        if let iss = self.iss {
            guard iss.value == "https://monurlsecure.com" else { // Vérifie l'émetteur
                throw JWTError.claimVerificationFailure(name: "iss", reason: "Émetteur invalide")
            }
        }
        if let aud = self.aud {
            try aud.verifyIntendedAudience(includes: "app-mobile") // Vérification si "app-mobile" est dans l'audience
        }

        // Vérifications custom
        guard !roles.isEmpty else {
            throw JWTError.claimVerificationFailure(name: "roles", reason: "Aucun rôle défini")
        }
        guard isVerified else {
            throw JWTError.claimVerificationFailure(name: "verified", reason: "Utilisateur non vérifié")
        }
    }
}

import Vapor
import Crypto

struct PasswordUtils {
    // Hasher un mot de passe avec SHA256 (temporaire - à remplacer par bcrypt)
    static func hash(_ password: String) throws -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Vérifier un mot de passe
    static func verify(_ password: String, against hash: String) throws -> Bool {
        let passwordHash = try self.hash(password)
        return passwordHash == hash
    }
    
    // Générer un mot de passe temporaire pour les tests
    static func generateTempPassword() -> String {
        return "temp_password"
    }
}
import Vapor
import BCrypt
import Crypto

struct PasswordUtils {
    // Hasher un mot de passe avec Bcrypt (sécurisé)
    static func hash(_ password: String) throws -> String {
        return try Bcrypt.hash(password)
    }
    
    // Vérifier un mot de passe avec Bcrypt
    static func verify(_ password: String, against hash: String) throws -> Bool {
        return try Bcrypt.verify(password, created: hash)
    }
    
    // Générer un mot de passe sécurisé aléatoirement
    static func generateSecurePassword(length: Int = 12) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    // Générer un mot de passe temporaire pour les tests (à utiliser uniquement en développement)
    static func generateTempPassword() -> String {
        #if DEBUG
        return "temp_password_dev_only"
        #else
        return generateSecurePassword()
        #endif
    }
    
    // Valider la force d'un mot de passe
    static func validatePasswordStrength(_ password: String) -> PasswordStrength {
        let minLength = 8
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        
        if password.count < minLength {
            return .weak("Le mot de passe doit contenir au moins \(minLength) caractères")
        }
        
        let criteriaCount = [hasUppercase, hasLowercase, hasNumbers, hasSpecialChars].filter { $0 }.count
        
        switch criteriaCount {
        case 0...1:
            return .weak("Le mot de passe doit contenir des majuscules, minuscules, chiffres et caractères spéciaux")
        case 2:
            return .medium("Mot de passe acceptable mais pourrait être renforcé")
        case 3:
            return .strong("Mot de passe fort")
        case 4:
            return .veryStrong("Mot de passe très fort")
        default:
            return .medium("Mot de passe acceptable")
        }
    }
}

enum PasswordStrength {
    case weak(String)
    case medium(String)
    case strong(String)
    case veryStrong(String)
    
    var isAcceptable: Bool {
        switch self {
        case .weak:
            return false
        case .medium, .strong, .veryStrong:
            return true
        }
    }
    
    var message: String {
        switch self {
        case .weak(let msg), .medium(let msg), .strong(let msg), .veryStrong(let msg):
            return msg
        }
    }
}


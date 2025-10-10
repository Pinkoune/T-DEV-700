import Vapor
import FirebaseFirestore
import FirebaseFirestoreSwift

public func testFirestore(app: Application) async throws {
    let firestore = app.firestore
    print("Test de connexion Firestore...")
    
    // Test de création
    let testUser = User(
        firstName: "Test",
        lastName: "User",
        email: "test@example.com",
        phone: "0123456789"
    )
    
    do {
        // Encode manuellement l'objet en dictionnaire
        let userData = try Firestore.Encoder().encode(testUser)
        
        // Utilisez addDocument(data:) qui supporte async
        let docRef = try await firestore.collection("users").addDocument(data: userData)
        print("Document créé avec succès : \(docRef.documentID)")
        
        // Test de lecture
        let document = try await docRef.getDocument()
        if document.exists {
            // Decode manuellement le dictionnaire en objet
            let retrievedUser = try Firestore.Decoder().decode(User.self, from: document.data()!)
            print("Document lu avec succès : \(retrievedUser.fullName)")
        }
        
        // Nettoyage (delete() supporte async)
        try await docRef.delete()
        print("Document supprimé avec succès")
        
        print("Firestore fonctionne parfaitement !")
    } catch {
        print("Erreur Firestore : \(error)")
        throw error
    }
}

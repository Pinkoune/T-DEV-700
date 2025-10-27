//
//  EditEmailSpace.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//

import SwiftUI

struct EditEmailSpace: View {
    @Binding var email: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    init(email: Binding<String>, firstName: Binding<String>, lastName: Binding<String>) {
        self._email = email
        self._firstName = firstName
        self._lastName = lastName
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    EditTextField(
                        title: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    if showSuccess {
                        Text("Email mis à jour avec succès!")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .padding()
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    ActionButton(title: isLoading ? "Enregistrement..." : "Enregistrer") {
                        saveEmail()
                    }
                    .frame(height: 55)
                    .disabled(isLoading)
                }
                .padding(20)
            }
            .navigationTitle("Modifier l'Email")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundStyle(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func saveEmail() {
        errorMessage = ""
        showSuccess = false
        
        if !isValidEmail(email) {
            errorMessage = "Veuillez entrer un email valide"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let response = try await UserService.updateProfile(
                    firstName: firstName,
                    lastName: lastName,
                    email: email
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    print("Email mis à jour: \(response.user.email)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    print("Erreur: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

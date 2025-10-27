//
//  EditProfileSpace.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//

import SwiftUI

struct EditProfileSpace: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    init(firstName: Binding<String>, lastName: Binding<String>, email: Binding<String>) {
        self._firstName = firstName
        self._lastName = lastName
        self._email = email
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    EditTextField(title: "Prénom", text: $firstName)
                    EditTextField(title: "Nom", text: $lastName)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    if showSuccess {
                        Text("Profil mis à jour avec succès!")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .padding()
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    ActionButton(title: isLoading ? "Enregistrement..." : "Enregistrer") {
                        saveProfile()
                    }
                    .frame(height: 55)
                    .disabled(isLoading)
                }
                .padding(20)
            }
            .navigationTitle("Modifier le profil")
            .foregroundStyle(.white)
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func saveProfile() {
        errorMessage = ""
        showSuccess = false
        
        if firstName.isEmpty || lastName.isEmpty {
            errorMessage = "Le prénom et le nom ne peuvent pas être vides"
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
                    print("Profil mis à jour: \(response.user.fullName)")
                    
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
}

struct EditTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            TextField("", text: $text)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
        }
    }
}

//
//  EmployeeAccount.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//
import SwiftUI

struct EmployeeAccount: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var showDeleteAlert = false
    @State private var showDisconnectAlert = false
    @State private var showEditProfile = false
    @State private var showEditEmail = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showLogin = false
    @State private var isLoggingOut = false
    @State private var showLogoutSuccess = false
    
    var body: some View {
            ZStack {
                Color(.mainGreen)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(userType: .employee, title: "Mon compte")
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            PersonalInfoSpace(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                onEditProfile: { showEditProfile = true },
                                onEditEmail: { showEditEmail = true }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.vertical, 10)

                            PasswordSpace(
                                currentPassword: $currentPassword,
                                newPassword: $newPassword,
                                confirmPassword: $confirmPassword,
                                onSave: savePassword
                            )
                            
                            DisconnectButton(onDisconnect: {showDisconnectAlert = true })
                            
                            DeleteSpace(onDelete: { showDeleteAlert = true })
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }
                    
                    Spacer()
                }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSpace(
                firstName: $firstName,
                lastName: $lastName,
                email: $email
            )
        }
        .sheet(isPresented: $showEditEmail) {
            EditEmailSpace(
                email: $email,
                firstName: $firstName,
                lastName: $lastName
            )
        }
        .alert("Se déconnecter", isPresented: $showDisconnectAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Déconnexion", role: .destructive, action: disconnect)
        } message: {
            Text("Voulez-vous vous déconnecter de votre compte ?")
        }
        .alert("Supprimer mon compte", isPresented: $showDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive, action: deleteAccount)
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer votre compte ?")
        }
        .fullScreenCover(isPresented: $showLogin) {
            Login()
        }
        .alert("Déconnexion réussie", isPresented: $showLogoutSuccess) {
            Button("OK") {
                showLogin = true
            }
        } message: {
            Text("Vous avez été déconnecté avec succès")
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        firstName = UserDefaults.standard.string(forKey: "userFirstName") ?? ""
        lastName = UserDefaults.standard.string(forKey: "userLastName") ?? ""
        email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        
        print("Données chargées - Prénom: \(firstName), Nom: \(lastName), Email: \(email)")
        print("Token présent: \(AuthService.getToken() != nil)")
        
        if firstName.isEmpty && lastName.isEmpty && email.isEmpty && AuthService.getToken() != nil {
            print("Données utilisateur manquantes, déconnexion nécessaire")
            AuthService.clearLocalData()
            showLogin = true
        }
    }
    
    private func savePassword() {
        print("Saving password...")
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
    }
    
    private func disconnect() {
        isLoggingOut = true
        
        Task {
            do {
                try await AuthService.logout()
                
                await MainActor.run {
                    isLoggingOut = false
                    print("Déconnexion réussie!")
                    showLogoutSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                    print("Erreur lors de la déconnexion: \(error.localizedDescription)")
                    showLogoutSuccess = true
                }
            }
        }
    }
    
    private func deleteAccount() {
        print("Deleting account...")
    }
}

#Preview {
    EmployeeAccount()
}

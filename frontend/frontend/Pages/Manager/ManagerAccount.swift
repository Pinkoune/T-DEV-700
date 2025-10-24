//
//  EmployeeAccount.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//
import SwiftUI

struct ManagerAccount: View {
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
                lastName: $lastName
            )
        }
        .sheet(isPresented: $showEditEmail) {
            EditEmailSpace(
                email: $email
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
            Text("Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.")
        }
        .fullScreenCover(isPresented: $showLogin) {
            Login()
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        firstName = UserDefaults.standard.string(forKey: "userFirstName") ?? ""
        lastName = UserDefaults.standard.string(forKey: "userLastName") ?? ""
        email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
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
                    showLogin = true
                }
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                    print("Erreur lors de la déconnexion: \(error.localizedDescription)")
                    showLogin = true
                }
            }
        }
    }
    
    private func deleteAccount() {
        print("Deleting account...")
    }
}

#Preview {
    ManagerAccount()
}

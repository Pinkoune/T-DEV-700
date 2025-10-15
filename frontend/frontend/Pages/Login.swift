//
//  Login.swift
//  frontend
//
//  Created by Mathieu Exposito on 13/10/2025.
//

import SwiftUI

struct Login: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var showEmployeePage = false
    
    var body: some View {
        ZStack {
            Color(Color.mainGreen)
                .ignoresSafeArea()
            VStack(spacing: 25) {
                Spacer()
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.bottom, 20)
                
                Text("Bienvenue sur McTime")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal, 30)
                
                SecureField("Mot de passe", text: $password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal, 30)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    handleLogin()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Se connecter")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.mainYellow)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal, 30)
                .disabled(isLoading)
                
                Button(action: {
                    showEmployeePage = true
                }) {
                    Text("Aller à la page d'accueil")
                        .padding()
                        .background(Color.mainYellow)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("Mot de passe oublié ?")
                        .foregroundColor(.white)
                        .underline()
                }
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPassword()
        }
       
    }
    
    func handleLogin() {
        errorMessage = ""
        
        if email.isEmpty || password.isEmpty {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }
        
        if !isValidEmail(email) {
            errorMessage = "Veuillez entrer un email valide"
            return
        }
        
        if !isValidPassword(password) {
            errorMessage = "Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let response = try await AuthService.login(email: email, password: password)
                
                await MainActor.run {
                    isLoading = false
                    print("✅ Connexion réussie! Bienvenue \(response.user.fullName)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let uppercaseRegex = ".*[A-Z]+.*"
        guard password.range(of: uppercaseRegex, options: .regularExpression) != nil else { return false }
        
        let digitRegex = ".*[0-9]+.*"
        guard password.range(of: digitRegex, options: .regularExpression) != nil else { return false }
        
        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
        guard password.range(of: specialCharRegex, options: .regularExpression) != nil else { return false }
        
        return true
    }
}

#Preview {
    Login()
}

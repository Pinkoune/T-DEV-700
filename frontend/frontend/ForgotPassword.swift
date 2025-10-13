//
//  ForgotPassword.swift
//  frontend
//
//  Created by Mathieu Exposito on 13/10/2025.
//

import SwiftUI

struct ForgotPassword: View {
    @State private var email = ""
    @State private var message = ""
    @State private var isSuccess = false
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color("MainBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 20)
                
                Text("Mot de passe oublié ?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Entrez votre email pour recevoir un lien de réinitialisation")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal, 30)
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(isSuccess ? .green : .red)
                        .font(.subheadline)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    handlePasswordReset()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Envoyer le lien")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("ButtonColor"))
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal, 30)
                .disabled(isLoading)
                
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Retour à la connexion")
                    }
                    .foregroundColor(.white)
                }
                .padding(.top, 10)
                
                Spacer()
            }
        }
    }
    
    func handlePasswordReset() {
        message = ""
        
        if email.isEmpty {
            message = "Veuillez entrer votre email"
            isSuccess = false
            return
        }
        
        if !isValidEmail(email) {
            message = "Veuillez entrer un email valide"
            isSuccess = false
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            isSuccess = true
            message = "Un email de réinitialisation a été envoyé à \(email)"
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    ForgotPassword()
}

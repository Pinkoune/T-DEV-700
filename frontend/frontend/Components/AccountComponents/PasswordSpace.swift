//
//  PasswordSpace.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//

import SwiftUI

struct PasswordSpace: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Changer mot de passe")
                .font(.custom("McDonaldsHelvetica", size: 22))
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            PasswordField(title: "Mot de passe actuel", text: $currentPassword)
            PasswordField(title: "Nouveau mot de passe", text: $newPassword)
            PasswordField(title: "Confirmer le mot de passe", text: $confirmPassword)
            
            ActionButton(title: "Enregistrer", action: onSave)
                .padding(.top, 10)
        }
        .padding(25)
    }
}

struct PasswordField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            SecureField("", text: $text)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }
}

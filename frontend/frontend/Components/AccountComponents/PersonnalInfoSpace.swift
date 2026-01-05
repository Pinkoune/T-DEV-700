//
//  PersonnalInfoSpace.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//
import SwiftUI

struct PersonalInfoSpace: View {
    let firstName: String
    let lastName: String
    let email: String
    let onEditProfile: () -> Void
    let onEditEmail: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PersonalInfoRow(label: "Prénom : ", value: firstName)
            PersonalInfoRow(label: "Nom : ", value: lastName)
            
            ActionButton(title: "Modifier", action: onEditProfile)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.vertical, 10)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Adresse Email : ")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(email)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.mainYellow)
            }
            
            ActionButton(title: "Modifier Email", action: onEditEmail)
        }
        .padding(25)
    }
}

struct PersonalInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.mainYellow)
        }
    }
}

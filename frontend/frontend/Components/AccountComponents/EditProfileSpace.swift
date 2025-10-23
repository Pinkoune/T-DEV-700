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
    @Environment(\.dismiss) var dismiss
    
    init(firstName: Binding<String>, lastName: Binding<String>) {
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
                    EditTextField(title: "Prénom", text: $firstName)
                    EditTextField(title: "Nom", text: $lastName)
                    
                    Spacer()
                    
                    ActionButton(title: "Enregistrer") {
                        dismiss()
                    }
                    .frame(height: 55)
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

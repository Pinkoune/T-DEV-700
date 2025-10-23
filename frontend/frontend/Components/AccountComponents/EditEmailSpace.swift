//
//  EditEmailSpace.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//

import SwiftUI

struct EditEmailSpace: View {
    @Binding var email: String
    @Environment(\.dismiss) var dismiss
    
    init(email: Binding<String>) {
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
                    EditTextField(
                        title: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )
                    
                    Spacer()
                    
                    ActionButton(title: "Enregistrer") {
                        dismiss()
                    }
                    .frame(height: 55)
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
}

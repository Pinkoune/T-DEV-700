//
//  CreateTeamView.swift
//  Frontend
//
//  David
//

import SwiftUI

struct CreateTeamView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var teamName = ""
    @State private var teamDescription = ""
    @State private var selectedColor = TeamColors.available[0].hex
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var onTeamCreated: ((TeamResponse) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainYellow)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {

                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor) ?? .blue)
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.2), radius: 10)
                            
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        

                        VStack(spacing: 16) {

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nom de l'équipe")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Ex: Équipe Marketing", text: $teamName)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Décrivez l'équipe...", text: $teamDescription, axis: .vertical)
                                    .lineLimit(3...6)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Couleur de l'équipe")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                    ForEach(TeamColors.available, id: \.hex) { colorOption in
                                        ColorButton(
                                            color: Color(hex: colorOption.hex) ?? .blue,
                                            isSelected: selectedColor == colorOption.hex
                                        ) {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedColor = colorOption.hex
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.mainGreen.opacity(0.3))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aperçu")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            TeamPreviewCard(
                                name: teamName.isEmpty ? "Nom de l'équipe" : teamName,
                                description: teamDescription.isEmpty ? "Description de l'équipe" : teamDescription,
                                color: Color(hex: selectedColor) ?? .blue
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                        

                        Button(action: createTeam) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .mainGreen))
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Créer l'équipe")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.mainGreen)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Nouvelle équipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.mainYellow, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !teamName.trimmingCharacters(in: .whitespaces).isEmpty &&
        teamName.count >= 2 &&
        teamName.count <= 50
    }
    
    private func createTeam() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        

        guard let managerId = UserDefaults.standard.string(forKey: "userId") else {
            errorMessage = "Impossible de récupérer votre identifiant"
            showError = true
            isLoading = false
            return
        }
        
        Task {
            do {
                let team = try await TeamService.createTeam(
                    name: teamName.trimmingCharacters(in: .whitespaces),
                    description: teamDescription.trimmingCharacters(in: .whitespaces),
                    managerId: managerId,
                    color: selectedColor
                )
                
                await MainActor.run {
                    isLoading = false
                    onTeamCreated?(team)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Custom Components

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct TeamPreviewCard: View {
    let name: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.3.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.mainGreen)
        )
    }
}

// MARK: - Preview

#Preview {
    CreateTeamView()
}


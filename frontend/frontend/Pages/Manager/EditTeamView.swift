//
//  EditTeamView.swift
//  Frontend
//
//  David
//

import SwiftUI

struct EditTeamView: View {
    @Environment(\.dismiss) var dismiss
    
    let team: Team
    
    @State private var teamName: String
    @State private var teamDescription: String
    @State private var selectedColor: String
    @State private var isActive: Bool
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showDeleteConfirmation = false
    
    var onTeamUpdated: ((TeamResponse) -> Void)?
    var onTeamDeleted: (() -> Void)?
    
    init(team: Team, onTeamUpdated: ((TeamResponse) -> Void)? = nil, onTeamDeleted: (() -> Void)? = nil) {
        self.team = team
        self.onTeamUpdated = onTeamUpdated
        self.onTeamDeleted = onTeamDeleted
        _teamName = State(initialValue: team.name)
        _teamDescription = State(initialValue: team.description)
        _selectedColor = State(initialValue: team.color)
        _isActive = State(initialValue: team.isActive)
    }
    
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
                            

                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $isActive) {
                                    HStack {
                                        Image(systemName: isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(isActive ? .green : .red)
                                        Text("Équipe active")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .tint(.green)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.mainGreen.opacity(0.3))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Informations")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                InfoRow(icon: "person.2.fill", title: "Membres", value: "\(team.memberCount)")
                                Spacer()
                                InfoRow(icon: "chart.bar.fill", title: "Taille", value: team.teamSize)
                            }
                            
                            if let createdAt = team.createdAt {
                                InfoRow(
                                    icon: "calendar",
                                    title: "Créée le",
                                    value: formatDate(createdAt)
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mainGreen.opacity(0.3))
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 20)
                        

                        VStack(spacing: 12) {

                            Button(action: updateTeam) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .mainGreen))
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Enregistrer les modifications")
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
                            

                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Supprimer l'équipe")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Modifier l'équipe")
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
            .confirmationDialog(
                "Supprimer l'équipe ?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) {
                    deleteTeam()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action est irréversible. L'équipe sera désactivée.")
            }
        }
    }
    
    private var isFormValid: Bool {
        !teamName.trimmingCharacters(in: .whitespaces).isEmpty &&
        teamName.count >= 2 &&
        teamName.count <= 50
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func updateTeam() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let updatedTeam = try await TeamService.updateTeam(
                    id: team.id,
                    name: teamName.trimmingCharacters(in: .whitespaces),
                    description: teamDescription.trimmingCharacters(in: .whitespaces),
                    managerId: nil,
                    color: selectedColor,
                    isActive: isActive
                )
                
                await MainActor.run {
                    isLoading = false
                    onTeamUpdated?(updatedTeam)
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
    
    private func deleteTeam() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await TeamService.deleteTeam(id: team.id)
                
                await MainActor.run {
                    isLoading = false
                    onTeamDeleted?()
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

// MARK: - Info Row Component

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditTeamView(team: Team.sampleTeams[0])
}


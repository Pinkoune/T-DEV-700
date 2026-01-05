//
//  AddMemberView.swift
//  Frontend
//
//  David
//

import SwiftUI

struct AddMemberView: View {
    let team: Team
    var onMemberAdded: ((TeamMemberResponse) -> Void)?
    
    @Environment(\.dismiss) var dismiss
    
    @State private var allUsers: [TeamMember] = []
    @State private var currentMembers: Set<String> = []
    @State private var selectedUsers: Set<String> = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var isAdding = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var availableUsers: [TeamMember] {
        let filtered = allUsers.filter { user in
            !currentMembers.contains(user.id) && user.isActive
        }
        
        if searchText.isEmpty {
            return filtered
        }
        
        return filtered.filter { user in
            user.fullName.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText) ||
            (user.department ?? "").localizedCaseInsensitiveContains(searchText) ||
            (user.position ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainYellow)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Rechercher un employé...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    

                    if !selectedUsers.isEmpty {
                        HStack {
                            Text("\(selectedUsers.count) sélectionné\(selectedUsers.count > 1 ? "s" : "")")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Tout désélectionner") {
                                selectedUsers.removeAll()
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Spacer()
                    } else if availableUsers.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(searchText.isEmpty ? "Tous les employés sont déjà dans l'équipe" : "Aucun résultat trouvé")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                        Spacer()
                    } else {

                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(availableUsers) { user in
                                    SelectableUserRow(
                                        user: user,
                                        isSelected: selectedUsers.contains(user.id)
                                    ) {
                                        toggleSelection(user.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .padding(.bottom, 100)
                        }
                    }
                }
                

                if !selectedUsers.isEmpty {
                    VStack {
                        Spacer()
                        
                        Button(action: addSelectedMembers) {
                            HStack {
                                if isAdding {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .mainGreen))
                                } else {
                                    Image(systemName: "person.badge.plus")
                                    Text("Ajouter \(selectedUsers.count) membre\(selectedUsers.count > 1 ? "s" : "")")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.mainGreen)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 10)
                        }
                        .disabled(isAdding)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Ajouter des membres")
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
            .onAppear {
                loadData()
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func toggleSelection(_ userId: String) {
        if selectedUsers.contains(userId) {
            selectedUsers.remove(userId)
        } else {
            selectedUsers.insert(userId)
        }
    }
    
    private func loadData() {
        isLoading = true
        
        Task {
            do {

                async let usersTask = TeamService.getAllUsers()
                async let membersTask = TeamService.getTeamMembers(teamId: team.id)
                
                let (users, members) = try await (usersTask, membersTask)
                
                await MainActor.run {
                    allUsers = users.map { TeamMember(from: $0) }
                    currentMembers = Set(members.compactMap { $0.id })
                    isLoading = false
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
    
    private func addSelectedMembers() {
        isAdding = true
        
        Task {
            var addedCount = 0
            var lastAddedMember: TeamMemberResponse?
            
            for userId in selectedUsers {
                do {
                    try await TeamService.addMember(teamId: team.id, userId: userId)
                    addedCount += 1
                    

                    if let user = allUsers.first(where: { $0.id == userId }) {

                        lastAddedMember = TeamMemberResponse(
                            id: user.id,
                            firstName: user.firstName,
                            lastName: user.lastName,
                            fullName: user.fullName,
                            email: user.email,
                            phone: user.phone,
                            role: user.role,
                            displayRole: user.displayRole,
                            department: user.department,
                            position: user.position,
                            weeklyHoursTarget: user.weeklyHoursTarget,
                            isActive: user.isActive,
                            hireDate: user.hireDate,
                            createdAt: user.createdAt,
                            updatedAt: user.updatedAt
                        )
                    }
                } catch {

                    print("Erreur lors de l'ajout de \(userId): \(error)")
                }
            }
            
            await MainActor.run {
                isAdding = false
                
                if addedCount > 0 {
                    if let member = lastAddedMember {
                        onMemberAdded?(member)
                    }
                    dismiss()
                } else {
                    errorMessage = "Impossible d'ajouter les membres sélectionnés"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Selectable User Row

struct SelectableUserRow: View {
    let user: TeamMember
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.mainGreen)
                    }
                }
                

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 45, height: 45)
                    
                    Text(user.initials)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.fullName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        if let department = user.department {
                            Text(department)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        if user.department != nil && user.position != nil {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        if let position = user.position {
                            Text(position)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                

                Text(user.displayRole)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(user.isManager ? .mainYellow : .mainGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.mainGreen.opacity(0.8) : Color.mainGreen.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    AddMemberView(team: Team.sampleTeams[0])
}


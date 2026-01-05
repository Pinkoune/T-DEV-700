//
//  TeamMembersView.swift
//  Frontend
//
//  David
//

import SwiftUI

struct TeamMembersView: View {
    let team: Team
    
    @Environment(\.dismiss) var dismiss
    
    @State private var members: [TeamMember] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showAddMember = false
    @State private var memberToRemove: TeamMember?
    @State private var showRemoveConfirmation = false
    @State private var searchText = ""
    
    var filteredMembers: [TeamMember] {
        if searchText.isEmpty {
            return members
        }
        return members.filter { member in
            member.fullName.localizedCaseInsensitiveContains(searchText) ||
            member.email.localizedCaseInsensitiveContains(searchText) ||
            (member.position ?? "").localizedCaseInsensitiveContains(searchText)
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
                        
                        TextField("Rechercher un membre...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(team.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(members.count) membre\(members.count > 1 ? "s" : "")")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        

                        Button(action: { showAddMember = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.badge.plus")
                                Text("Ajouter")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.mainGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Spacer()
                    } else if members.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("Aucun membre dans cette équipe")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button(action: { showAddMember = true }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Ajouter des membres")
                                }
                                .fontWeight(.semibold)
                                .foregroundColor(.mainGreen)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(25)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredMembers) { member in
                                    MemberRow(
                                        member: member,
                                        isManager: member.id == team.managerId,
                                        onRemove: {
                                            memberToRemove = member
                                            showRemoveConfirmation = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("Membres de l'équipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.mainYellow, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                loadMembers()
            }
            .refreshable {
                await refreshMembers()
            }
            .sheet(isPresented: $showAddMember) {
                AddMemberView(team: team) { newMember in

                    members.append(TeamMember(from: newMember))
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                "Retirer ce membre ?",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Retirer", role: .destructive) {
                    if let member = memberToRemove {
                        removeMember(member)
                    }
                }
                Button("Annuler", role: .cancel) {
                    memberToRemove = nil
                }
            } message: {
                if let member = memberToRemove {
                    Text("\(member.fullName) sera retiré de l'équipe.")
                }
            }
        }
    }
    
    private func loadMembers() {
        isLoading = true
        
        Task {
            do {
                let memberResponses = try await TeamService.getTeamMembers(teamId: team.id)
                
                await MainActor.run {
                    members = memberResponses.map { TeamMember(from: $0) }
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
    
    private func refreshMembers() async {
        do {
            let memberResponses = try await TeamService.getTeamMembers(teamId: team.id)
            
            await MainActor.run {
                members = memberResponses.map { TeamMember(from: $0) }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func removeMember(_ member: TeamMember) {
        Task {
            do {
                try await TeamService.removeMember(teamId: team.id, userId: member.id)
                
                await MainActor.run {
                    members.removeAll { $0.id == member.id }
                    memberToRemove = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Member Row Component

struct MemberRow: View {
    let member: TeamMember
    let isManager: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(isManager ? Color.mainYellow : Color.white)
                    .frame(width: 50, height: 50)
                
                Text(member.initials)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isManager ? .white : .mainGreen)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.fullName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isManager {
                        Text("Manager")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.mainYellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                }
                
                if let position = member.position {
                    Text(position)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            

            if !isManager {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
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
    TeamMembersView(team: Team.sampleTeams[0])
}


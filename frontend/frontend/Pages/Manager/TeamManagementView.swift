import SwiftUI

struct TeamManagementView: View {
    let team: Team
    let onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var color: String = "#007AFF"
    @State private var managerId: String = ""
    @State private var members: [TeamMember] = []
    @State private var allUsers: [TeamMember] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showAddMemberSheet = false
    @State private var userToAdd: String?
    
    var availableUsers: [TeamMember] {
        allUsers.filter { user in
            !members.contains { $0.id == user.id }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            VStack(spacing: 0) {
                                Text("INFORMATIONS")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 8)
                                    .padding(.top, 16)
                                
                                VStack(spacing: 16) {
                                    CustomTextField(placeholder: "Nom de l'équipe", text: $name)
                                    Divider()
                                    CustomTextField(placeholder: "Description", text: $description)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                Text("COULEUR")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 8)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(TeamColors.available, id: \.hex) { item in
                                            Circle()
                                                .fill(Color(hex: item.hex) ?? .gray)
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                        .opacity(color == item.hex ? 1 : 0)
                                                )
                                                .overlay(
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.white)
                                                        .opacity(color == item.hex ? 1 : 0)
                                                )
                                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                .onTapGesture {
                                                    withAnimation {
                                                        color = item.hex
                                                    }
                                                }
                                        }
                                    }
                                    .padding()
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            // SECTION MEMBRES
                            VStack(spacing: 0) {
                                Text("MEMBRES (\(members.count))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 8)
                                
                                VStack(spacing: 0) {
                                    ForEach(members) { member in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(member.fullName)
                                                    .fontWeight(.medium)
                                                Text(member.displayRole)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            if member.id == managerId {
                                                Text("Manager")
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(8)
                                            } else {
                                                Button(action: {
                                                    Task { await removeMember(member.id) }
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                        .padding()
                                        
                                        if member != members.last {
                                            Divider()
                                                .padding(.leading)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(action: { showAddMemberSheet = true }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Ajouter un membre")
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding()
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                Text("ZONE DANGER")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 8)
                                
                                Button(action: {}) {
                                    Text("Supprimer l'équipe")
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                }
                                .opacity(0.5) // Indicatif
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Modifier l'équipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        Task { await saveTeam() }
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadInitialData()
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showAddMemberSheet) {
                MemberSelectionSheet(users: availableUsers) { userId in
                    Task {
                        await addMember(userId)
                    }
                }
            }
        }
    }
    
    // MARK: - Logic
    
    func loadInitialData() {
        self.name = team.name
        self.description = team.description
        self.color = team.color
        self.managerId = team.managerId
        
        loadTeamMembers()
        loadAllUsers()
    }
    
    func loadTeamMembers() {
        Task {
            do {
                let responses = try await TeamService.getTeamMembers(teamId: team.id)
                await MainActor.run {
                    self.members = responses.map { TeamMember(from: $0) }
                }
            } catch {
                print("Erreur chargement membres: \(error)")
            }
        }
    }
    
    func loadAllUsers() {
        Task {
            do {
                let responses = try await TeamService.getAllUsers()
                await MainActor.run {
                    self.allUsers = responses.map { TeamMember(from: $0) }
                        .filter { $0.role != "manager" }
                }
            } catch {
                print("Erreur chargement utilisateurs: \(error)")
            }
        }
    }
    
    func saveTeam() async {
        isLoading = true
        do {
            _ = try await TeamService.updateTeam(
                id: team.id,
                name: name,
                description: description,
                managerId: nil,
                color: color,
                isActive: nil
            )
            
            await MainActor.run {
                isLoading = false
                onSave()
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
    
    func addMember(_ userId: String) async {
        do {
            try await TeamService.addMember(teamId: team.id, userId: userId)
            loadTeamMembers()
            showAddMemberSheet = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func removeMember(_ userId: String) async {
        do {
            try await TeamService.removeMember(teamId: team.id, userId: userId)
            loadTeamMembers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .multilineTextAlignment(.center)
    }
}

struct MemberSelectionSheet: View {
    let users: [TeamMember]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(users) { user in
                Button(action: {
                    onSelect(user.id)
                    dismiss()
                }) {
                    HStack {
                        Text(user.fullName)
                        Spacer()
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("Ajouter un membre")
        }
    }
}

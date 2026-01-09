import SwiftUI

struct ManagerHomePage: View {
    @State private var teams: [Team] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showCreateTeam = false
    @State private var searchText = ""
    
    var filteredTeams: [Team] {
        if searchText.isEmpty {
            return teams
        }
        return teams.filter { team in
            team.name.localizedCaseInsensitiveContains(searchText) ||
            team.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.mainYellow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderView(userType: .manager, title: "Les équipes")
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Rechercher une équipe...", text: $searchText)
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
                
                HStack {
                    Text("Gérer les équipes (\(filteredTeams.count))")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showCreateTeam = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Créer")
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
                .padding(.top, 12)
                .padding(.bottom, 5)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Spacer()
                } else if teams.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Aucune équipe")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Créez votre première équipe pour commencer")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showCreateTeam = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Créer une équipe")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.mainGreen)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else if filteredTeams.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Aucun résultat pour \"\(searchText)\"")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTeams) { team in
                                NavigationLink(destination: TeamDashboard(team: team)) {
                                    TeamCardEnhanced(team: team)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical)
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            loadTeams()
        }
        .refreshable {
            await refreshTeams()
        }
        .sheet(isPresented: $showCreateTeam) {
            CreateTeamView { newTeam in
                teams.insert(Team(from: newTeam), at: 0)
            }
        }
        .alert("Erreur", isPresented: $showError) {
            Button("Réessayer") {
                loadTeams()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadTeams() {
        isLoading = true
        
        Task {
            do {
                let managerId = UserDefaults.standard.string(forKey: "userId") ?? ""
                
                let teamResponses: [TeamResponse]
                if !managerId.isEmpty {
                    teamResponses = try await TeamService.getTeamsByManager(managerId: managerId)
                } else {
                    teamResponses = try await TeamService.getActiveTeams()
                }
                
                await MainActor.run {
                    teams = teamResponses.map { Team(from: $0) }
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
    
    private func refreshTeams() async {
        do {
            let managerId = UserDefaults.standard.string(forKey: "userId") ?? ""
            
            let teamResponses: [TeamResponse]
            if !managerId.isEmpty {
                teamResponses = try await TeamService.getTeamsByManager(managerId: managerId)
            } else {
                teamResponses = try await TeamService.getActiveTeams()
            }
            
            await MainActor.run {
                teams = teamResponses.map { Team(from: $0) }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Enhanced Team Card

struct TeamCardEnhanced: View {
    let team: Team
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(team.uiColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: team.sizeIcon)
                    .foregroundColor(.white)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                        
                        Text("\(team.memberCount)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(team.teamSize)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(team.isActive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.title3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.mainGreen)
        )
        .padding(.horizontal, 15)
    }
}

#Preview {
    ManagerHomePage()
}

//
//  TeamDashboard.swift MAJ
//  Frontend
//
//  David
//

import SwiftUI

struct TeamDashboard: View {
    let team: Team
    
    @State private var members: [TeamMember] = []
    @State private var stats: TeamStatsResponse?
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showingTeamStats = false
    @State private var showEditSheet = false
    @State private var selectedMember: TeamMember?
    @State private var showEditTeam = false
    @State private var showManageMembers = false
    @State private var currentTeam: Team
    
    init(team: Team) {
        self.team = team
        _currentTeam = State(initialValue: team)
    }
    
    var body: some View {
        ZStack {
            Color(.mainYellow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderView(userType: .manager, title: currentTeam.name)
                    .padding(.top)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    
                    if let stats = stats {
                        StatsTeamCardLive(stats: stats)
                            .padding(.horizontal, 10)
                    } else {
                        StatsTeamCard()
                            .padding(.horizontal, 10)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: { showingTeamStats = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.bar.fill")
                                Text("Statistiques")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                        }
                        
                        Button(action: { showEditTeam = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                Text("Modifier")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.mainGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.4))
                        .padding(.top, 10)
                    
                    HStack {
                        Text("Membres de l'équipe (\(members.count))")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { showManageMembers = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.badge.plus")
                                Text("Gérer")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.mainGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    
                    if members.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("Aucun membre dans cette équipe")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button(action: { showManageMembers = true }) {
                                Text("Ajouter des membres")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.mainGreen)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(20)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(members) { member in
                                    TeamMemberCard(
                                        member: member,
                                        isManager: member.id == currentTeam.managerId
                                    )
                                    .onTapGesture {
                                        print("Employé sélectionné: \(member.fullName)")
                                        self.selectedMember = member
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        .padding(.bottom, 130)
                    }
                }
            }
            .padding(.top, -70)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadTeamData()
        }
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showingTeamStats) {
            StatsTeam(team: currentTeam, stats: stats)
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            Task {
                loadTeamData()
            }
        }) {
            TeamManagementView(team: team, onSave: {
                Task {
                   loadTeamData()
                }
            })
        }
        .sheet(item: $selectedMember) { member in
            EmployeeStatsView(
                employeeName: member.fullName,
                teamId: currentTeam.id,
                userId: member.id
            )
        }
        .sheet(isPresented: $showEditTeam) {
            EditTeamView(team: currentTeam) { updatedTeam in
                currentTeam = Team(from: updatedTeam)
            }
        }
        .sheet(isPresented: $showManageMembers, onDismiss: {
            Task {
               loadTeamData()
            }
        }) {
            TeamMembersView(team: currentTeam)
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadTeamData() {
        isLoading = true
        
        Task {
            do {
                async let membersTask = TeamService.getTeamMembers(teamId: team.id)
                async let statsTask = TeamService.getTeamStats(teamId: team.id)
                
                let (memberResponses, teamStats) = try await (membersTask, statsTask)
                
                await MainActor.run {
                    members = memberResponses.map { TeamMember(from: $0) }
                    stats = teamStats
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
    
    private func refreshData() async {
        do {
            async let membersTask = TeamService.getTeamMembers(teamId: team.id)
            async let statsTask = TeamService.getTeamStats(teamId: team.id)
            
            let (memberResponses, teamStats) = try await (membersTask, statsTask)
            
            await MainActor.run {
                members = memberResponses.map { TeamMember(from: $0) }
                stats = teamStats
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Team Member Card

struct TeamMemberCard: View {
    let member: TeamMember
    let isManager: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isManager ? Color.mainYellow : Color.white)
                    .frame(width: 50, height: 50)
                
                Text(member.initials)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isManager ? .white : .mainGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.fullName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isManager {
                        HStack(spacing: 2) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                            Text("Manager")
                                .font(.caption2)
                        }
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
                
                if let department = member.department {
                    Text(department)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(member.isActive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(member.displayRole)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
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


struct StatsTeamCardLive: View {
    let stats: TeamStatsResponse
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatMiniItem(
                    value: "\(stats.totalMembers)",
                    label: "Membres",
                    icon: "person.fill"
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                StatMiniItem(
                    value: String(format: "%.0f%%", stats.averagePerformance),
                    label: "Performance",
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                StatMiniItem(
                    value: "\(stats.activeTimeEntries)",
                    label: "Actifs",
                    icon: "clock.fill"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mainGreen)
            )
        }
    }
}

struct StatMiniItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        TeamDashboard(team: Team.sampleTeams[0])
    }
}

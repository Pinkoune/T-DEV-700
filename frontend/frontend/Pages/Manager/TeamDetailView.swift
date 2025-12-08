//
//  TeamDetailView.swift
//  Frontend
//
//  David
//

import SwiftUI

struct TeamDetailView: View {
    let teamId: String
    
    @Environment(\.dismiss) var dismiss
    
    @State private var team: Team?
    @State private var members: [TeamMember] = []
    @State private var manager: TeamMember?
    @State private var stats: TeamStatsResponse?
    @State private var performances: [TeamMemberPerformance] = []
    
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showEditTeam = false
    @State private var showMembers = false
    @State private var showStats = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainYellow)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if let team = team {
                    ScrollView {
                        VStack(spacing: 20) {

                            TeamHeaderCard(team: team, manager: manager)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            

                            if let stats = stats {
                                QuickStatsCard(stats: stats)
                                    .padding(.horizontal, 20)
                            }
                            

                            VStack(spacing: 12) {
                                ActionRow(
                                    icon: "person.3.fill",
                                    title: "Membres de l'équipe",
                                    subtitle: "\(members.count) membre\(members.count > 1 ? "s" : "")",
                                    color: .blue
                                ) {
                                    showMembers = true
                                }
                                
                                ActionRow(
                                    icon: "chart.bar.fill",
                                    title: "Statistiques détaillées",
                                    subtitle: "Performance et KPIs",
                                    color: .purple
                                ) {
                                    showStats = true
                                }
                                
                                ActionRow(
                                    icon: "pencil.circle.fill",
                                    title: "Modifier l'équipe",
                                    subtitle: "Nom, description, couleur",
                                    color: .orange
                                ) {
                                    showEditTeam = true
                                }
                            }
                            .padding(.horizontal, 20)
                            

                            if !members.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Membres récents")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button("Voir tous") {
                                            showMembers = true
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    ForEach(members.prefix(3)) { member in
                                        MemberPreviewRow(member: member, isManager: member.id == team.managerId)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.mainGreen.opacity(0.3))
                                )
                                .padding(.horizontal, 20)
                            }
                            

                            if !performances.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Performance de l'équipe")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    ForEach(performances.prefix(5)) { perf in
                                        PerformanceRow(performance: perf)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.mainGreen.opacity(0.3))
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            Spacer(minLength: 50)
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Équipe non trouvée")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .navigationTitle(team?.name ?? "Équipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                
                if team != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { showEditTeam = true }) {
                                Label("Modifier", systemImage: "pencil")
                            }
                            
                            Button(action: { showMembers = true }) {
                                Label("Gérer les membres", systemImage: "person.3")
                            }
                            
                            Button(action: { showStats = true }) {
                                Label("Statistiques", systemImage: "chart.bar")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(Color.mainYellow, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                loadTeamDetails()
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showEditTeam) {
                if let team = team {
                    EditTeamView(team: team) { updatedTeam in
                        self.team = Team(from: updatedTeam)
                    } onTeamDeleted: {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMembers) {
                if let team = team {
                    TeamMembersView(team: team)
                }
            }
            .sheet(isPresented: $showStats) {
                if let team = team {
                    StatsTeamDetailView(team: team, stats: stats, performances: performances)
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadTeamDetails() {
        isLoading = true
        
        Task {
            do {
                let detail = try await TeamService.getTeam(id: teamId)
                

                async let statsTask = TeamService.getTeamStats(teamId: teamId)
                async let perfTask = TeamService.getTeamPerformance(teamId: teamId)
                
                let (fetchedStats, fetchedPerf) = try await (statsTask, perfTask)
                
                await MainActor.run {
                    team = Team(from: detail.team)
                    members = detail.members.map { TeamMember(from: $0) }
                    if let managerResponse = detail.manager {
                        manager = TeamMember(from: managerResponse)
                    }
                    stats = fetchedStats
                    performances = fetchedPerf
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
            let detail = try await TeamService.getTeam(id: teamId)
            let fetchedStats = try await TeamService.getTeamStats(teamId: teamId)
            let fetchedPerf = try await TeamService.getTeamPerformance(teamId: teamId)
            
            await MainActor.run {
                team = Team(from: detail.team)
                members = detail.members.map { TeamMember(from: $0) }
                if let managerResponse = detail.manager {
                    manager = TeamMember(from: managerResponse)
                }
                stats = fetchedStats
                performances = fetchedPerf
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Team Header Card

struct TeamHeaderCard: View {
    let team: Team
    let manager: TeamMember?
    
    var body: some View {
        VStack(spacing: 16) {

            ZStack {
                Circle()
                    .fill(team.uiColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: team.uiColor.opacity(0.5), radius: 10)
                
                Image(systemName: team.sizeIcon)
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            

            VStack(spacing: 4) {
                Text(team.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !team.description.isEmpty {
                    Text(team.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            

            if let manager = manager {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.mainYellow)
                    
                    Text("Manager: \(manager.fullName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.mainGreen.opacity(0.5))
                )
            }
            

            HStack(spacing: 8) {
                Circle()
                    .fill(team.isActive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(team.isActive ? "Équipe active" : "Équipe inactive")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.mainGreen)
        )
    }
}

// MARK: - Quick Stats Card

struct QuickStatsCard: View {
    let stats: TeamStatsResponse
    
    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(stats.totalMembers)", label: "Membres", icon: "person.fill")
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            StatItem(
                value: String(format: "%.0f%%", stats.averagePerformance),
                label: "Performance",
                icon: "chart.line.uptrend.xyaxis"
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            StatItem(
                value: String(format: "%.0f%%", stats.latenessRate),
                label: "Retards",
                icon: "clock.fill"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.mainGreen.opacity(0.5))
        )
    }
}

struct StatItem: View {
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

// MARK: - Action Row

struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 45, height: 45)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
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
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Member Preview Row

struct MemberPreviewRow: View {
    let member: TeamMember
    let isManager: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isManager ? Color.mainYellow : Color.white.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(member.initials)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(isManager ? .white : .white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(member.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if isManager {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.mainYellow)
                    }
                }
                
                if let position = member.position {
                    Text(position)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Performance Row

struct PerformanceRow: View {
    let performance: TeamMemberPerformance
    
    var performanceColor: Color {
        guard let perf = performance.latestPerformance else { return .gray }
        switch perf {
        case 90...100: return .green
        case 75..<90: return .blue
        case 60..<75: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(performance.userName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    if performance.isManager {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.mainYellow)
                    }
                }
                
                Text(performance.performanceLevel)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if let perf = performance.latestPerformance {
                Text(String(format: "%.0f%%", perf))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(performanceColor)
            } else {
                Text("N/A")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Stats Team Detail View (Sheet)

struct StatsTeamDetailView: View {
    let team: Team
    let stats: TeamStatsResponse?
    let performances: [TeamMemberPerformance]
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainYellow)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let stats = stats {

                            StatCard(
                                title: "Performance moyenne",
                                value: String(format: "%.1f%%", stats.averagePerformance),
                                icon: "chart.line.uptrend.xyaxis",
                                trend: stats.averagePerformance >= 75 ? .up : stats.averagePerformance >= 50 ? .neutral : .down
                            )
                            

                            StatCard(
                                title: "Membres actifs",
                                value: "\(stats.totalMembers)",
                                icon: "person.3.fill",
                                trend: .neutral
                            )
                            

                            StatCard(
                                title: "Taux de retard",
                                value: String(format: "%.1f%%", stats.latenessRate),
                                icon: "clock.badge.exclamationmark.fill",
                                trend: stats.latenessRate <= 10 ? .up : stats.latenessRate <= 25 ? .neutral : .down
                            )
                            

                            StatCard(
                                title: "Retard moyen",
                                value: String(format: "%.0f min", stats.averageLateMinutes),
                                icon: "timer",
                                trend: stats.averageLateMinutes <= 15 ? .up : stats.averageLateMinutes <= 30 ? .neutral : .down
                            )
                            

                            StatCard(
                                title: "Pointages actifs",
                                value: "\(stats.activeTimeEntries)",
                                icon: "clock.fill",
                                trend: .neutral
                            )
                        }
                        

                        if let stats = stats {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Taille de l'équipe")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(stats.teamSize)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                if stats.isLargeTeam {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text("Grande équipe")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.2))
                                    )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.mainGreen)
                            )
                            .padding(.horizontal, 15)
                        }
                        

                        if !performances.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Performance individuelle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                
                                ForEach(performances) { perf in
                                    PerformanceDetailRow(performance: perf)
                                        .padding(.horizontal, 15)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Statistiques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.mainYellow, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct PerformanceDetailRow: View {
    let performance: TeamMemberPerformance
    
    var performanceColor: Color {
        guard let perf = performance.latestPerformance else { return .gray }
        switch perf {
        case 90...100: return .green
        case 75..<90: return .blue
        case 60..<75: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat((performance.latestPerformance ?? 0) / 100))
                    .stroke(performanceColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                if let perf = performance.latestPerformance {
                    Text(String(format: "%.0f", perf))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(performance.userName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if performance.isManager {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.mainYellow)
                    }
                }
                
                Text(performance.performanceLevel)
                    .font(.subheadline)
                    .foregroundColor(performanceColor)
            }
            
            Spacer()
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
    TeamDetailView(teamId: "1")
}


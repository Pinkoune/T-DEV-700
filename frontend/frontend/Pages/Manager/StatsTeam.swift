//
//  StatsTeam.swift MAJ
//  Frontend
//
//  David
//

import SwiftUI

struct StatsTeam: View {
    let team: Team?
    let stats: TeamStatsResponse?
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = false
    @State private var liveStats: TeamStatsResponse?
    
    init(team: Team? = nil, stats: TeamStatsResponse? = nil) {
        self.team = team
        self.stats = stats
    }
    
    var currentStats: TeamStatsResponse? {
        liveStats ?? stats
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainYellow)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(team?.name ?? "Statistiques de l'équipe")
                        .font(.custom("McDonaldsHelvetica", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                if let stats = currentStats {
                                    
                                    StatCard(
                                        title: "Membres de l'équipe",
                                        value: "\(stats.totalMembers)",
                                        icon: "person.3.fill",
                                        trend: .neutral
                                    )
                                    
                                    StatCard(
                                        title: "Pointages actifs",
                                        value: "\(stats.activeTimeEntries)",
                                        icon: "clock.fill",
                                        trend: stats.activeTimeEntries > 0 ? .up : .neutral
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
                                        title: "Retards ce mois",
                                        value: "\(stats.totalLateEntries)",
                                        icon: "exclamationmark.triangle.fill",
                                        trend: stats.totalLateEntries <= 5 ? .up : stats.totalLateEntries <= 15 ? .neutral : .down
                                    )
                                    
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Taille de l'équipe")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Text(stats.teamSize)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.mainYellow)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.white)
                                                )
                                        }
                                        
                                        if stats.isLargeTeam {
                                            HStack(spacing: 8) {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundColor(.orange)
                                                
                                                Text("Grande équipe - pensez à la diviser pour une meilleure gestion")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
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
                                    
                                } else {
                                    
                                    StatCard(
                                        title: "Membres",
                                        value: "0",
                                        icon: "person.3.fill",
                                        trend: .neutral
                                    )
                                    
                                    Text("Aucune statistique disponible")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.top, 20)
                                }
                                
                            }
                            .padding(.vertical)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        guard let team = team else { return }
        
        isLoading = true
        
        Task {
            do {
                let newStats = try await TeamService.getTeamStats(teamId: team.id)
                
                await MainActor.run {
                    liveStats = newStats
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: Trend
    
    enum Trend {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .font(.caption)
            }
            .foregroundColor(trend.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(trend.color.opacity(0.2))
            )
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
    StatsTeam(team: Team.sampleTeams[0], stats: nil)
}

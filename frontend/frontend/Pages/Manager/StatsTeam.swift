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
    
    @State private var performances: [TeamMemberPerformance] = []
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
                                        title: "Performance moyenne",
                                        value: String(format: "%.1f%%", stats.averagePerformance),
                                        icon: "chart.line.uptrend.xyaxis",
                                        trend: stats.averagePerformance >= 75 ? .up : stats.averagePerformance >= 50 ? .neutral : .down
                                    )
                                    
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
                                        title: "Performance",
                                        value: "N/A",
                                        icon: "chart.line.uptrend.xyaxis",
                                        trend: .neutral
                                    )
                                    
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
                                
                                if !performances.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Performance individuelle")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        ForEach(performances) { perf in
                                            PerformanceRowSimple(performance: perf)
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
                loadPerformances()
            }
        }
    }
    
    private func loadPerformances() {
        guard let team = team else { return }
        
        isLoading = true
        
        Task {
            do {
                async let perfTask = TeamService.getTeamPerformance(teamId: team.id)
                async let statsTask = TeamService.getTeamStats(teamId: team.id)
                
                let (perfs, newStats) = try await (perfTask, statsTask)
                
                await MainActor.run {
                    performances = perfs
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

// MARK: - Performance Row Simple

struct PerformanceRowSimple: View {
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
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: CGFloat((performance.latestPerformance ?? 0) / 100))
                    .stroke(performanceColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                if let perf = performance.latestPerformance {
                    Text(String(format: "%.0f", perf))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(performance.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if performance.isManager {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.mainYellow)
                    }
                }
                
                Text(performance.performanceLevel)
                    .font(.caption)
                    .foregroundColor(performanceColor)
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
        .padding(.vertical, 4)
    }
}

// MARK: - StatCard (conservé pour compatibilité)

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

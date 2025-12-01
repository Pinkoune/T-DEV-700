import SwiftUI

// informations fausses à remplacer

struct StatsTeam: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainYellow)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Statistiques de l'équipe")
                        .font(.custom("McDonaldsHelvetica", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            StatCard(
                                title: "Productivité",
                                value: "87%",
                                icon: "chart.line.uptrend.xyaxis",
                                trend: .up
                            )
                            
                            StatCard(
                                title: "Tâches complétées",
                                value: "124",
                                icon: "checkmark.circle.fill",
                                trend: .up
                            )
                            
                            StatCard(
                                title: "Heures travaillées",
                                value: "320h",
                                icon: "clock.fill",
                                trend: .neutral
                            )
                            
                            StatCard(
                                title: "Projets actifs",
                                value: "8",
                                icon: "folder.fill",
                                trend: .down
                            )
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Performance hebdomadaire")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach(0..<7) { index in
                                        VStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white)
                                                .frame(width: 30, height: CGFloat.random(in: 50...150))
                                            
                                            Text(["L", "M", "M", "J", "V", "S", "D"][index])
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.mainGreen.opacity(0.3))
                                )
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.mainGreen)
                            )
                            .padding(.horizontal, 15)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Composant StatCard
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
                Text(trend == .neutral ? "=" : trend == .up ? "+12%" : "-5%")
                    .font(.caption)
                    .fontWeight(.semibold)
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

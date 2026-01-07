import SwiftUI
import Charts

struct EmployeeStatsView: View {
    let employeeName: String
    let teamId: String
    let userId: String
    
    @State private var weeklyHours: Double = 0.0
    @State private var latenessCount: Int = 0
    @State private var taskCompletionRate: Double = 0.0
    @State private var dailyStats: [DailyStats] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainYellow.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if !errorMessage.isEmpty {
                    VStack {
                        Text("Erreur")
                            .font(.title)
                            .foregroundColor(.white)
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .padding()
                        Button("Réessayer") {
                            loadStats()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            HStack {
                                Text(employeeName)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.white)
                                    Text("Heures Hebdomadaires")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(.bottom, 5)
                                
                                Text(String(format: "%.1f h", weeklyHours))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Moyenne sur les 7 derniers jours")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [.mainGreen, .second]), startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.white)
                                    Text("Retards (Ce mois)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(.bottom, 5)
                                
                                Text("\(latenessCount)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Nombre de fois arrivé après l'heure prévue")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [.mainGreen, .second]), startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "chart.bar.xaxis")
                                        .foregroundColor(.white)
                                    Text("Évolution (7 jours)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(.bottom, 10)
                                
                                Chart(dailyStats) { item in
                                    BarMark(
                                        x: .value("Date", item.date),
                                        y: .value("Heures", item.hours)
                                    )
                                    .foregroundStyle(.white)
                                    .annotation(position: .top) {
                                        Text(String(format: "%.1f", item.hours))
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(height: 150)
                                .chartYAxis {
                                    AxisMarks(position: .leading, values: .automatic) {
                                        AxisValueLabel().foregroundStyle(.white)
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic) {
                                        AxisValueLabel().foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [.mainGreen, .second]), startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                loadStats()
            }
        }
    }
    
    func loadStats() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                print("Chargement des stats pour user \(userId) team \(teamId)")
                let stats = try await TeamService.getMemberStats(teamId: teamId, userId: userId)
                
                await MainActor.run {
                    self.weeklyHours = stats.averageWeeklyHours
                    self.latenessCount = stats.latenessCount
                    self.taskCompletionRate = stats.taskCompletionRate
                    self.dailyStats = stats.lastSevenDays ?? []
                    self.isLoading = false
                }
            } catch {
                print("Erreur: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

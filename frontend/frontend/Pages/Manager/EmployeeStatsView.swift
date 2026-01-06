import SwiftUI

struct EmployeeStatsView: View {
    let employeeName: String
    let teamId: String
    let userId: String
    
    @State private var weeklyHours: Double = 0.0
    @State private var latenessCount: Int = 0
    @State private var taskCompletionRate: Double = 0.0
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
                                        .foregroundColor(.mainGreen)
                                    Text("Heures Hebdomadaires")
                                        .font(.headline)
                                        .foregroundColor(.mainGreen)
                                }
                                .padding(.bottom, 5)
                                
                                Text(String(format: "%.1f h", weeklyHours))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.mainGreen)
                                
                                Text("Moyenne sur les 7 derniers jours")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(latenessCount > 0 ? .red : .mainGreen)
                                    Text("Retards (Ce mois)")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.bottom, 5)
                                
                                Text("\(latenessCount)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(latenessCount > 0 ? .red : .mainGreen)
                                
                                Text("Nombre de fois arrivé après l'heure prévue")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(15)
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

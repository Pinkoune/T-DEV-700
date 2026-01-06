import SwiftUI

struct EmployeeStatsView: View {
    @State var employeeName: String = "Employé"
    @State var teamId: String
    @State var userId: String
    
    @State var weeklyHours: Double = 0.0
    @State var latenessCount: Int = 0
    @State var taskRate: Double = 0.0
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    
                    Text("Statistiques de \(employeeName)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    
                    VStack {
                        Text("Heures cette semaine")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(String(format: "%.1f", weeklyHours)) h")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Image(systemName: "clock.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        Text("Nombre de retards (ce mois)")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(latenessCount > 0 ? .red : .green)
                            
                            Text("\(latenessCount)")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        if latenessCount == 0 {
                            Text("Parfait ! Continuez comme ça.")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Text("Attention à la ponctualité.")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    
                    

                    
                    Spacer()
                }
            }
            .navigationTitle("Détails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadStats()
            }
        }
    }
    
    func loadStats() {
        Task {
            do {
                print("Chargement des stats pour user \(userId) team \(teamId)")
                let stats = try await TeamService.getMemberStats(teamId: teamId, userId: userId)
                
                self.weeklyHours = stats.averageWeeklyHours
                self.latenessCount = stats.latenessCount
                self.taskRate = stats.taskCompletionRate
                
            } catch {
                print("Erreur: \(error)")
            }
        }
    }
}

#Preview {
    EmployeeStatsView(employeeName: "Test", teamId: "test", userId: "456")
}

import SwiftUI

struct TeamDashboard: View {
    let team: Team
    @State private var employees: [Employee] = Employee.sampleEmployees
    @State private var showingTeamStats = false
    
    var body: some View {
        ZStack {
            Color(.mainYellow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderView(userType: .manager, title: team.name)
                    .padding(.top)
                
                StatsTeamCard()
                    .padding(.horizontal, 10)
                
                Button(action: {
                    showingTeamStats = true
                }) {
                    Text("Statistiques de l'équipe")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 90)
                        .padding(.vertical, 10)
                        .background(Color.mainYellow)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(Color.white, lineWidth: 0.5)
                                .shadow(
                                    color: .mainGreen.opacity(1.0),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 200))
                                .blendMode(.multiply)
                        )
                }
                .padding(.top, 10)
                
                Divider()
                    .background(Color.white.opacity(0.4))
                    .padding(.top, 10)
                
                HStack {
                    Text("Membres de l'équipe (\(employees.count))")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(employees) { employee in
                            EmployeeCard(employee: employee)
                                .onTapGesture {
                                    print("Employé sélectionné: \(employee.fullName)")
                                }
                        }
                    }
                    .padding(.vertical)
                }
                .padding(.bottom, 130)
            }
            .padding(.top, -70)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingTeamStats) {
            StatsTeam()
        }
    }
}


#Preview {
    NavigationStack {
        TeamDashboard(team: Team.sampleTeams[0])
    }
}

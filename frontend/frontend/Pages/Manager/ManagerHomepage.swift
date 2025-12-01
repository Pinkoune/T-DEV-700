import SwiftUI

struct ManagerHomePage: View {
    @State private var teams = Team.sampleTeams
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainYellow)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(userType: .manager, title: "Les équipes")
                    HStack {
                        Text("Gérer les équipes")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, -5)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(teams) { team in
                                NavigationLink(destination: TeamDashboard(team: team)) {
                                    TeamCard(team: team)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical)
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ManagerHomePage()
}

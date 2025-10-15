// MARK: - ContentView for ManagerHomepage
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
                                TeamCard(team: team)
                                    .onTapGesture {
                                        // Faire le lien vers les pages concernées
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                    .padding(.bottom, 100)
                }
                
            }
        }

    }
}

#Preview {
    ManagerHomePage()
}

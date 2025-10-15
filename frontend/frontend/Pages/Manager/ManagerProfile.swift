import SwiftUI

struct ManagerProfile: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "login.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            Text("Le Profil")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Gérez vos employés ici")
                .foregroundColor(.gray)
        }
    }
}

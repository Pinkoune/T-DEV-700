import SwiftUI

struct StatsTeamCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                Text("Moyenne d'heures hebdomadaire")
                    .font(.custom("McDonaldsHelvetica", size: 23))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .padding(.leading, 30)
                Spacer()
            }
            
            HStack {
                Text("60h 30min")
                    .font(.custom("McDonaldsHelvetica", size: 27))
                    .fontWeight(.bold)
                    .foregroundColor(.mainYellow)
                    .padding(.top, 5)
                    .padding(.vertical, 5)
                    .frame(width: 250, alignment: .leading)
                    .padding(.leading, 15)
            }
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.second.opacity(1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        LinearGradient(gradient: Gradient(colors: [.mainGreen, .second]), startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    .blur(radius: 2)
                    .offset(x: 0, y: 0)
                    .mask(RoundedRectangle(cornerRadius: 5))
            )
            .padding()
            .padding(.leading, 10)

        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(gradient: Gradient(colors: [.mainGreen, .second]), startPoint: .leading, endPoint: .trailing)
                )
        )
    }

}

#Preview {
    StatsTeamCard()
}

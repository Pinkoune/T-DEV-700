import SwiftUI

struct PointerCardMini: View {
    let isActive: Bool
    let hoursWorked: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.mainYellow)
                    .font(.system(size: 14))
                Text(isActive ? "En cours" : "Pas pointé")
                    .font(.custom("McDonaldsHelvetica", size: 16))
                    .foregroundColor(.white)
                Spacer()
                Circle()
                    .fill(isActive ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Text(formatHours(hoursWorked))
                .font(.custom("McDonaldsHelvetica", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.mainYellow)
                .padding(.horizontal, 20)
            
            HStack {
                Spacer()
                Text(formatDate(Date()))
                    .font(.custom("McDonaldsHelvetica", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.mainGreen, .second]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(
            color: .white.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return String(format: "%d:%02d", h, m)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    PointerCardMini(isActive: true, hoursWorked: 4.45)
}
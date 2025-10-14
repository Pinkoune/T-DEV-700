import SwiftUI

struct PointerCardMini: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBadge()
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            DateLabel()
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(gradient: Gradient(colors: [.mainGreen, .second]), startPoint: .leading, endPoint: .trailing)
                )
        )
        .shadow(
            color: .white.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
    }

}

#Preview {
    EmployeeDashboard()
}

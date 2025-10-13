import SwiftUI

struct StatusBadge: View {
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.mainYellow)
                .font(.system(size: 14))
            Text("En cours")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
        }
    }
}

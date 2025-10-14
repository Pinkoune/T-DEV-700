// MARK: - HeaderView.swift

// A modifier, voir s'il est possible de rentrer des variables de texte
import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "apple.logo")
                .font(.system(size: 40, weight: .regular))
                .foregroundColor(.mainYellow)
            
            Text("Bonjour Ronald,")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
}

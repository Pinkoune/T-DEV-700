// Ajouter le disabled du bouton une fois cliquer

import SwiftUI

struct PointerBtn: View {
    var body: some View {
        Button(action: {
            // Action à ajouter pour collecter le pointage
        }) {
            VStack(spacing: 4) {
                Text("COLLECTER+")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("(Pointer le début du journée)")
                    .font(.system(size: 12))
                    .foregroundColor(.mainGreen.opacity(0.9))
            }
            .frame(maxWidth: 300)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.mainYellow)
            )
        }
    }
}

#Preview {
    PointerBtn()
}

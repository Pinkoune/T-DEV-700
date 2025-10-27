// MARK: - HeaderView.swift

// A modifier, voir s'il est possible de rentrer des variables de texte
import SwiftUI

enum UserType {
    case employee
    case manager
}

struct HeaderView: View {
    let userType: UserType
    let title: String
    
    var appleColor: Color {
        switch userType {
        case .employee:
            return .mainYellow
        case .manager:
            return .mainGreen
        }
    }
    
    var body: some View {
        Image(systemName: "apple.logo")
            .font(.system(size: 60))
            .foregroundStyle(appleColor)
            .onLongPressGesture(minimumDuration: 5) {
                AudioManager.shared.toggleBackgroundAmbient()
            }
            .accessibilityAddTraits(.isButton)
        HStack {
            Text(title)
                .font(.custom("McDonaldsHelvetica", size: 28))
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
    }
}

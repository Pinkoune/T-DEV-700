// MARK: - HeaderView.swift

// A modifier, voir s'il est possible de rentrer des variables de texte
import SwiftUI


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
        
        HStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
    }
}

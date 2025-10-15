// MARK: - HeaderView.swift

// A modifier, voir s'il est possible de rentrer des variables de texte
import SwiftUI

struct HeaderView: View {
    let title: String
    
    var body: some View {
        Image(.mcApple)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 100, maxHeight: 60)
        
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

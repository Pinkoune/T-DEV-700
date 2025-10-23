import SwiftUI

struct NavbarIcons: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: size * 0.45))
                    .foregroundColor(color)
            )
    }
}

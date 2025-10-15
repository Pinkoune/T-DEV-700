import SwiftUI

struct TimerCircle: View {
    let hours: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.mainYellow, lineWidth: 4)
                .frame(width: 80, height: 80)
            
            Text(hours)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.mainYellow)
        }
    }
}

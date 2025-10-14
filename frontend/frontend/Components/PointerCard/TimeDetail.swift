import SwiftUI

struct TimeDetail: View {
    let label: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text(time)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.mainYellow)
        }
    }
}

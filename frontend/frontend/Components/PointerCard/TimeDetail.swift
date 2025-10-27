import SwiftUI

struct TimeDetail: View {
    let label: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("McDonaldsHelvetica", size: 18))
                .foregroundColor(.white)
            Text(time)
                .font(.custom("McDonaldsHelvetica", size: 22))
                .foregroundColor(.mainYellow)
        }
    }
}

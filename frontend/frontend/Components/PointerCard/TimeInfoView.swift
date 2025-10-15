import SwiftUI

struct TimeInfoView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            TimerCircle(hours: "6 h")
            
            VStack(alignment: .leading, spacing: 12) {
                TimeDetail(label: "Heure d'arrivée", time: "8:30")
                TimeDetail(label: "Heure de départ", time: "-")
            }
            
            Spacer()
        }
    }
}

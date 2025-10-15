import SwiftUI

struct TeamCard: View {
    let team: Team
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.3.fill")
                    .foregroundColor(.black)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text("\(team.memberCount) membre\(team.memberCount > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
                .font(.title3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.mainGreen)
        )
        .padding(.horizontal, 15)
    }
}

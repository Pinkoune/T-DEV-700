import SwiftUI

struct BattlePassDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let currentLevel: Int
    let currentExp: Int
    let claimedRewards: [Int]
    let onClaim: (Int) -> Void
    
    static let gradient = LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
    
    var body: some View {
        ZStack {
            Self.gradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Battle Pass Saison 1")
                        .font(.custom("McDonaldsHelvetica", size: 20))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                     Image(systemName: "xmark")
                        .foregroundColor(.clear)
                        .padding(10)
                }
                .padding()
                
                VStack(spacing: 5) {
                    Text("Niveau \(currentLevel)")
                        .font(.custom("McDonaldsHelvetica", size: 30))
                        .foregroundColor(.mainYellow)
                        .fontWeight(.bold)
                    
                    Text("\(currentExp) / 1000 XP (Niveau suivant)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 20)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(BattlePassConfig.levels) { level in
                            BattlePassLevelRow(
                                level: level,
                                currentLevel: currentLevel,
                                isClaimed: claimedRewards.contains(level.level),
                                onClaim: { onClaim(level.level) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct BattlePassConfig {
    static let levels: [BattlePassLevel] = (1...20).map { level in
        let reward: (String, String, Bool)
        switch level {
        case 1: reward = ("Café Offert", "cup.and.saucer.fill", true)
        case 3: reward = ("Petite Frite", "flame.fill", true)
        case 5: reward = ("McFlurry", "snowflake", true)
        case 8: reward = ("Cheeseburger", "circle.circle.fill", true)
        case 10: reward = ("Big Mac", "crown.fill", true)
        case 12: reward = ("Nuggets x6", "oval.fill", true)
        case 15: reward = ("Menu Best Of", "bag.fill", true)
        case 20: reward = ("Menu Maxi Best Of", "star.circle.fill", true)
        default: reward = ("100 Points Fidélité", "star.fill", false)
        }
        
        return BattlePassLevel(level: level, requiredExp: level * 1000, rewardName: reward.0, rewardIcon: reward.1, isImportant: reward.2)
    }
}

struct BattlePassLevel: Identifiable {
    let id = UUID()
    let level: Int
    let requiredExp: Int
    let rewardName: String
    let rewardIcon: String
    let isImportant: Bool
}

struct BattlePassLevelRow: View {
    let level: BattlePassLevel
    let currentLevel: Int
    let isClaimed: Bool
    let onClaim: () -> Void
    
    var isUnlocked: Bool {
        return currentLevel >= level.level
    }
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.mainYellow : Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                if level.isImportant {
                    Image(systemName: level.rewardIcon)
                        .font(.system(size: 24))
                        .foregroundColor(isUnlocked ? .black : .white)
                } else {
                    Text("\(level.level)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isUnlocked ? .black : .white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Niveau \(level.level)")
                    .font(.custom("McDonaldsHelvetica", size: 16))
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Text(level.rewardName)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            if isUnlocked {
                if isClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Button(action: onClaim) {
                        Text("Récupérer")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isUnlocked ? Color.mainYellow.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    BattlePassDetailView(currentLevel: 5, currentExp: 450, claimedRewards: [1, 3], onClaim: { _ in })
}

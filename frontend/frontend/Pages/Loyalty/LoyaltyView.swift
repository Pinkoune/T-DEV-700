import SwiftUI

struct LoyaltyView: View {
    @State private var points: Int = 0
    @State private var inventory: [String] = []
    @State private var battlePassExp: Int = 0
    @State private var dailyQuests: [DailyQuest] = []
    @State private var claimedRewards: [Int] = []
    @State private var userId: String = ""
    @State private var isLoading = false
    @State private var showBattlePassDetail = false
    @State private var showSnakeGame = false
    @Environment(\.presentationMode) var presentationMode
    
    var level: Int {
        return (battlePassExp / 1000)
    }
    
    var currentLevelExp: Int {
        return battlePassExp % 1000
    }
    
    var expProgress: Double {
        return Double(currentLevelExp) / 1000.0
    }
    
    let shopItems = [
        ShopItem(name: "Café", cost: 50, icon: "cup.and.saucer.fill", color: .brown),
        ShopItem(name: "Cravate", cost: 200, icon: "tshirt.fill", color: .blue),
        ShopItem(name: "Sieste", cost: 500, icon: "bed.double.fill", color: .purple),
        ShopItem(name: "Joker Retard", cost: 1000, icon: "clock.badge.exclamationmark.fill", color: .red)
    ]
    
    var body: some View {
        ZStack {
            Color(.mainGreen)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Simplified Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Fidélité")
                        .font(.custom("McDonaldsHelvetica", size: 20))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Points Display - More compact
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.mainYellow)
                        Text("\(points)")
                            .font(.custom("McDonaldsHelvetica", size: 16))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                    .background(Color.black.opacity(0.2))
                    .cornerRadius(20)
                    .onLongPressGesture(minimumDuration: 5.0) {
                        showSnakeGame = true
                    }
                    .fullScreenCover(isPresented: $showSnakeGame) {
                        SnakeGameView(userId: userId)
                    }
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Battle Pass Section
                        BattlePassCard(level: level, currentExp: currentLevelExp, progress: expProgress) {
                            showBattlePassDetail = true
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showBattlePassDetail) {
                            BattlePassDetailView(currentLevel: level, currentExp: currentLevelExp, claimedRewards: claimedRewards) { levelToClaim in
                                claimReward(level: levelToClaim)
                            }
                        }
                        
                        // Daily Quests Section (Blue Card)
                        DailyQuestsCard(quests: dailyQuests)
                            .padding(.horizontal)
                        
/* Inventory Section */
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Inventaire")
                                .font(.custom("McDonaldsHelvetica", size: 18))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if inventory.isEmpty {
                                Text("Vide")
                                    .font(.custom("McDonaldsHelvetica", size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(Set(inventory)).sorted(), id: \.self) { itemName in
                                            let count = inventory.filter { $0 == itemName }.count
                                            InventoryItemCard(
                                                name: itemName,
                                                count: count,
                                                onUse: { useReward(item: itemName) }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Shop Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Boutique")
                                .font(.custom("McDonaldsHelvetica", size: 18))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(shopItems) { item in
                                    ShopItemCard(
                                        item: item,
                                        userPoints: points,
                                        onBuy: { buyReward(item: item) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 10)
                }
            }
            
            if isLoading {
                Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                ProgressView()
                    .tint(.white)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        guard let storedId = UserDefaults.standard.string(forKey: "userId") else { return }
        userId = storedId
        isLoading = true
        
        Task {
            do {
                let user = try await UserService.getUser(userId: userId)
                await MainActor.run {
                    self.points = user.loyaltyPoints ?? 0
                    self.inventory = user.inventory ?? []
                    self.battlePassExp = user.battlePassExp ?? 0
                    self.dailyQuests = user.dailyQuests ?? []
                    self.claimedRewards = user.claimedRewards ?? []
                    self.isLoading = false
                }
            } catch {
                print("Error loading user: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func buyReward(item: ShopItem) {
        isLoading = true
        Task {
            do {
                let updatedUser = try await LoyaltyService.buyReward(userId: userId, item: item.name, cost: item.cost)
                await MainActor.run {
                    self.points = updatedUser.loyaltyPoints ?? 0
                    self.inventory = updatedUser.inventory ?? []
                    self.isLoading = false
                }
            } catch {
                print("Error buying reward: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func useReward(item: String) {
        isLoading = true
        Task {
            do {
                let updatedUser = try await LoyaltyService.useReward(userId: userId, item: item)
                await MainActor.run {
                    self.points = updatedUser.loyaltyPoints ?? 0
                    self.inventory = updatedUser.inventory ?? []
                    self.isLoading = false
                }
            } catch {
                print("Error using reward: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func claimReward(level: Int) {
        isLoading = true
        Task {
            do {
                let updatedUser = try await LoyaltyService.claimReward(userId: userId, level: level)
                await MainActor.run {
                    self.points = updatedUser.loyaltyPoints ?? 0
                    self.inventory = updatedUser.inventory ?? []
                    self.claimedRewards = updatedUser.claimedRewards ?? []
                    self.isLoading = false
                }
            } catch {
                print("Error claiming reward: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Components
    
    struct BattlePassCard: View {
        let level: Int
        let currentExp: Int
        let progress: Double
        let onTap: () -> Void
        
        // Find next IMPORTANT reward
        var nextReward: BattlePassLevel? {
            return BattlePassConfig.levels.first { $0.level >= level && $0.isImportant }
        }
        
        var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Battle Pass")
                            .font(.custom("McDonaldsHelvetica", size: 18))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if let reward = nextReward {
                            HStack(spacing: 5) {
                                Text("Prochaine:")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Image(systemName: reward.rewardIcon)
                                    .font(.system(size: 20)) // Bigger icon
                                    .foregroundColor(.mainYellow)
                            }
                        } else {
                            Text("Niveau \(level)")
                                .font(.custom("McDonaldsHelvetica", size: 18))
                                .foregroundColor(.mainYellow)
                                .fontWeight(.bold)
                        }
                    }
                    
                    // Progress Bar (Shorter length, left aligned)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.3))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(gradient: Gradient(colors: [.mainYellow, .orange]), startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, min(geometry.size.width * CGFloat(progress), geometry.size.width)), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.trailing, 130) // Significantly shorter and left aligned
                    
                    HStack {
                        Text("\(currentExp) / 1000 XP")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("Niveau \(level)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(15)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    struct DailyQuestsCard: View {
        let quests: [DailyQuest]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Quêtes Quotidiennes")
                    .font(.custom("McDonaldsHelvetica", size: 18))
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                if quests.isEmpty {
                    Text("Aucune quête active")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    ForEach(quests) { quest in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quest.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("+\(quest.reward) XP")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.mainYellow)
                                
                                // Progress bar per quest
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.black.opacity(0.2))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white)
                                            .frame(width: max(0, min(g.size.width * CGFloat(Double(quest.progress) / Double(max(quest.target, 1))), g.size.width)), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                            
                            Spacer()
                            
                            if quest.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Text("\(quest.progress)/\(quest.target)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if quest.id != quests.last?.id {
                            Divider().background(Color.white.opacity(0.1))
                        }
                    }
                }
            }
            .padding(15)
            .background(Color.blue.opacity(0.9)) // "Encadré bleu qui rentre dans le thème" - using a simpler blue tone
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }
    
    struct ShopItem: Identifiable {
        let id = UUID()
        let name: String
        let cost: Int
        let icon: String
        let color: Color
    }
    
    struct ShopItemCard: View {
        let item: ShopItem
        let userPoints: Int
        let onBuy: () -> Void
        
        var body: some View {
            VStack {
                ZStack {
                    Circle()
                        .fill(item.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 24))
                        .foregroundColor(item.color)
                }
                .padding(.bottom, 4)
                
                Text(item.name)
                    .font(.custom("McDonaldsHelvetica", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.mainYellow)
                    Text("\(item.cost)")
                        .font(.custom("McDonaldsHelvetica", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button(action: {
                    onBuy()
                }) {
                    Text(userPoints >= item.cost ? "Acheter" : "Bloqué")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(userPoints >= item.cost ? Color.mainGreen : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(userPoints < item.cost)
                .padding(.top, 4)
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    struct InventoryItemCard: View {
        let name: String
        let count: Int
        let onUse: () -> Void
        
        var itemConfig: (icon: String, color: Color) {
            switch name {
            case "Café": return ("cup.and.saucer.fill", .brown)
            case "Cravate": return ("tshirt.fill", .blue)
            case "Sieste": return ("bed.double.fill", .purple)
            case "Joker Retard": return ("clock.badge.exclamationmark.fill", .red)
            default: return ("cube.box.fill", .gray)
            }
        }
        
        var body: some View {
            VStack {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(itemConfig.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: itemConfig.icon)
                        .font(.system(size: 24))
                        .foregroundColor(itemConfig.color)
                        .frame(width: 50, height: 50)
                    
                    if count > 1 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 5, y: -5)
                    }
                }
                .padding(.bottom, 4)
                
                Text(name)
                    .font(.custom("McDonaldsHelvetica", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Button(action: {
                    onUse()
                }) {
                    Text("Utiliser")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .frame(width: 100)
        }
    }
    
}

#Preview {
    LoyaltyView()
}

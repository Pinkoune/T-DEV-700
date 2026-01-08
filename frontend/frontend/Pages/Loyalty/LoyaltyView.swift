import SwiftUI

struct LoyaltyView: View {
    @State private var points: Int = 0
    @State private var inventory: [String] = []
    @State private var userId: String = ""
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    
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
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    Spacer()
                    
                    Text("Fidélité")
                        .font(.custom("McDonaldsHelvetica", size: 20))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Points Display
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.mainYellow)
                        Text("\(points)")
                            .font(.custom("McDonaldsHelvetica", size: 18))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Inventory Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Mon Inventaire")
                                .font(.custom("McDonaldsHelvetica", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if inventory.isEmpty {
                                Text("Votre inventaire est vide.")
                                    .font(.custom("McDonaldsHelvetica", size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal)
                                    .padding(.vertical, 20)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
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
                        .padding(.top, 20)
                        
                        // Shop Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Boutique")
                                .font(.custom("McDonaldsHelvetica", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
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
                        
                        // Battle Pass Placeholder
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Battle Pass")
                                .font(.custom("McDonaldsHelvetica", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.bottom, 10)
                                Text("Saison 1 - Bientôt disponible")
                                    .font(.custom("McDonaldsHelvetica", size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 50)
                    }
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
                    // Ideally show error alert
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
                    .frame(width: 60, height: 60)
                
                Image(systemName: item.icon)
                    .font(.system(size: 30))
                    .foregroundColor(item.color)
            }
            .padding(.bottom, 8)
            
            Text(item.name)
                .font(.custom("McDonaldsHelvetica", size: 16))
                .foregroundColor(.white)
                .fontWeight(.medium)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.mainYellow)
                Text("\(item.cost)")
                    .font(.custom("McDonaldsHelvetica", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Button(action: {
                onBuy()
            }) {
                Text(userPoints >= item.cost ? "Acheter" : "Bloqué")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(userPoints >= item.cost ? Color.mainGreen : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(userPoints < item.cost)
            .padding(.top, 5)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

struct InventoryItemCard: View {
    let name: String
    let count: Int
    let onUse: () -> Void
    
    // Helper to find icon/color based on name (simple mapping)
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
                    .frame(width: 60, height: 60)
                
                Image(systemName: itemConfig.icon)
                    .font(.system(size: 30))
                    .foregroundColor(itemConfig.color)
                    .frame(width: 60, height: 60)
                
                if count > 1 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 5, y: -5)
                }
            }
            .padding(.bottom, 8)
            
            Text(name)
                .font(.custom("McDonaldsHelvetica", size: 14))
                .foregroundColor(.white)
                .fontWeight(.medium)
            
            Button(action: {
                onUse()
            }) {
                Text("Utiliser")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .frame(width: 120)
    }
}

#Preview {
    LoyaltyView()
}

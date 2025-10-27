import SwiftUI

struct ManagerView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            Group {
                if selectedTab == 0 {
                    NavigationStack {
                        ManagerHomePage()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .navigationBarHidden(true)
                    }
                } else {
                    NavigationStack {
                        ManagerAccount()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .navigationBarHidden(true)
                    }
                }
            }
            
            VStack {
                Spacer()
                SliderNavbar(selectedTab: $selectedTab)
            }
            .allowsHitTesting(true)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct SliderNavbar: View {
    @Binding var selectedTab: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    let buttonSpacing: CGFloat = 80
    let buttonWidth: CGFloat = 50
    let circleSize: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .bottom) {
            BottomShape()
                .fill(.mainGreen)
                .frame(height: 200)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            
            ZStack {
                HStack(spacing: buttonSpacing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 0
                        }
                    }) {
                        Image(.store)
                            .resizable()
                            .scaledToFit()
                            .frame(width: buttonWidth, height: buttonWidth)
                    }
                
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 1
                        }
                    }) {
                        Image(.fries)
                            .resizable()
                            .scaledToFit()
                            .frame(width: buttonWidth, height: buttonWidth)
                            .foregroundColor(selectedTab == 1 ? .green : .white.opacity(0.6))
                    }
                }
                
                Circle()
                    .fill(Color.yellow)
                    .frame(width: circleSize, height: circleSize)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .offset(x: calculateCircleOffset())
                    .animation(isDragging ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                dragOffset = value.translation.width
                                
                                let basePosition = selectedTab == 0 ? -(buttonSpacing + buttonWidth) / 2 : (buttonSpacing + buttonWidth) / 2
                                let totalOffset = basePosition + dragOffset
                                
                                if totalOffset > 0 {
                                    selectedTab = 1
                                } else {
                                    selectedTab = 0
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                dragOffset = 0
                            }
                    )
                    .zIndex(-1)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(.mainGreen.opacity(1))
                    .shadow(color: .greenNavbar.opacity(0.8), radius: 10, x: 0, y: 0)
                    .padding(.horizontal, 20)
                    .padding(.vertical, -5)
                    .padding(.bottom, 40)
            )
        }
    }
    
    private func calculateCircleOffset() -> CGFloat {
        let baseOffset = selectedTab == 0 ? -(buttonSpacing + buttonWidth) / 2 : (buttonSpacing + buttonWidth) / 2
        return baseOffset + (isDragging ? dragOffset : 0)
    }
}

#Preview {
    ManagerView()
}

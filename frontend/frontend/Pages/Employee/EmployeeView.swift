import SwiftUI

struct EmployeeView: View {
    @State private var selectedTab: Int = 1
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainGreen)
                    .ignoresSafeArea()
                
                TabView(selection: $selectedTab) {
                    EmployeeDashboard()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(0)

                    EmployeeHomePage()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(1)
                    
                    EmployeeAccount()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.15), value: selectedTab)
                
                VStack {
                    Spacer()
                    SliderEmployeeNavbar(selectedTab: $selectedTab)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .animation(.easeInOut(duration: 0.15), value: selectedTab)
        }
    }
}

struct SliderEmployeeNavbar: View {
    @Binding var selectedTab: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    let buttonSpacing: CGFloat = 30
    let buttonWidth: CGFloat = 50
    let circleSize: CGFloat = 80
    
    enum IconType {
        case systemImage(String)
        case customImage(ImageResource)
    }
    
    private var orderedButtons: [(icon: IconType, index: Int)] {
        return [
            (.customImage(.store), 0),
            (.customImage(.fries), 1), 
            (.customImage(.burger), 2)
        ]
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            BottomShape()
                .fill(.mainYellow)
                .frame(height: 200)
//                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
            
            HStack(spacing: buttonSpacing) {
                ForEach(0..<orderedButtons.count, id: \.self) { position in
                    let buttonData = orderedButtons[position]
                    let isSelected = buttonData.index == selectedTab
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = buttonData.index
                        }
                    }) {
                        ZStack {
                          
                            Circle()
                                .fill(.white)
                                .frame(width: circleSize, height: circleSize)
                                .scaleEffect(isSelected ? 1 : 0.8)
                            
                            
                            Group {
                                switch buttonData.icon {
                                case .systemImage(let systemName):
                                    Image(systemName: systemName)
                                        .resizable()
                                        .scaledToFit()
                                case .customImage(let imageResource):
                                    Image(imageResource)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                            .frame(width: buttonWidth, height: buttonWidth)
                            .foregroundColor(isSelected ? .mainYellow : .gray)
                        }
                        .scaleEffect(isSelected ? 1.2 : 1)
                    }
                    .offset(y: isSelected ? -20 : 0)
                    
                }
            }
            .padding(.bottom, 30)
        }
    }
}

#Preview {
    EmployeeView()
}

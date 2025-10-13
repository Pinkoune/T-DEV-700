import SwiftUI

struct Navbar: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            BottomShape()
                .fill(.mainYellow)
                .frame(height: 200)
//                .position(x: 200, y: 750)
            
            HStack(spacing: 40) {
                NavbarIcons(systemName: "calendar", color: .mainGreen, size: 60)
                NavbarIcons(systemName: "fork.knife", color: .red, size: 90)
                    .padding(.bottom, 40)
                NavbarIcons(systemName: "cart.fill", color: .mainGreen, size: 60)
            }
            .padding(.bottom)
//            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    EmployeeHomePageView()
}

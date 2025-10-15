import SwiftUI

struct Navbar: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            BottomShape()
                .fill(.mainYellow)
                .frame(height: 200)
//                .position(x: 200, y: 750)
            
            HStack(spacing: 40) {
                NavigationLink(destination: EmployeeDashboard()) {
                    NavbarIcons(systemName: "calendar", color: .mainGreen, size: 60)
                }
                .navigationBarBackButtonHidden(true)
                
                NavigationLink(destination: EmployeeHomePage()) {
                    NavbarIcons(systemName: "fork.knife", color: .red, size: 90)
                        .padding(.bottom, 40)
                }
                .navigationBarBackButtonHidden(true)
                
                NavigationLink(destination: EmployeeAccount()) {
                    NavbarIcons(systemName: "person.crop.circle", color: .mainGreen, size: 60)
                }
                .navigationBarBackButtonHidden(true)
            }
            .padding(.bottom)
//            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    EmployeeHomePage()
}

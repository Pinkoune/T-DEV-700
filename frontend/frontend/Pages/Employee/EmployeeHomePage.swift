// MARK: - ContentView for EmployeeHomepage
import SwiftUI

struct EmployeeHomePage: View {
    
    var body: some View {
        ZStack {
            Color(.mainGreen)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderView(title: "Bonjour Ronald,")

                PointerCard()
                    .padding(.horizontal, 16)
                
                PointerBtn()
                    .padding(.horizontal, 40)
                    .padding(.top, 30)
                
                Spacer()
            }
            
            VStack{
                Spacer()
                Navbar()
                    .ignoresSafeArea(edges: .all)
                    
                  .padding(.bottom, 0)

            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    EmployeeHomePage()
}

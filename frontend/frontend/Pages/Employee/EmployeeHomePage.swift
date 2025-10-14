// MARK: - ContentView for EmployeeHomepage
import SwiftUI

struct EmployeeHomePageView: View {
    
    var body: some View {
        ZStack {
            Color(.mainGreen)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundColor(.mainYellow)
                
                
                HStack {
                    Text("Bonjour Ronald,")
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()

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
    EmployeeHomePageView()
}

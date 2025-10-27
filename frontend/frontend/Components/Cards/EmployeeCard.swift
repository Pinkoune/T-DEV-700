import SwiftUI

struct EmployeeCard: View {
    let employee: Employee
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar de l'employé
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                
                Text(employee.firstName.prefix(1) + employee.lastName.prefix(1))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.mainGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.fullName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(employee.role)
                    .font(.subheadline)
                    .foregroundColor(.gray)
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

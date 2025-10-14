import SwiftUI

struct BottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: rect.height * 0.3))
        
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.19),
            control: CGPoint(x: rect.width * 0.25, y: rect.height * 0.05)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.19),
            control: CGPoint(x: rect.width * 0.25, y: rect.height * 0.05)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.3),
            control: CGPoint(x: rect.width * 0.75, y: rect.height * 0.25)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    EmployeeHomePageView()
}

import SwiftUI
import Firebase
import FirebaseFirestore

struct CapsulePillBadge: View {
    let text: String
    let colorLeft: Color
    let colorRight: Color

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // 왼쪽 반원
                Path { path in
                    path.addArc(center: CGPoint(x: h/2, y: h/2), radius: h/2, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                    path.addLine(to: CGPoint(x: w/2, y: 0))
                    path.addLine(to: CGPoint(x: w/2, y: h))
                    path.closeSubpath()
                }
                .fill(colorLeft)
                
                // 오른쪽 반원
                Path { path in
                    path.addArc(center: CGPoint(x: w - h/2, y: h/2), radius: h/2, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
                    path.addLine(to: CGPoint(x: w/2, y: h))
                    path.addLine(to: CGPoint(x: w/2, y: 0))
                    path.closeSubpath()
                }
                .fill(colorRight)
            }
            .clipShape(Capsule())
            
            Text(text)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .multilineTextAlignment(.center)
        }
        .frame(width: 60, height: 36)
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
    }
}

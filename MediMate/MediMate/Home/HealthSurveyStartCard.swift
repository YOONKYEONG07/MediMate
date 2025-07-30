import SwiftUI

struct HealthSurveyStartCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🩺 건강 상태 체크하기")
                .font(.headline)

            Text("간단한 설문으로 당신에게 맞는 영양제를 추천받아보세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            NavigationLink(destination: HealthSurveyView()) {
                Text("건강 상태 체크하기")
                    .fontWeight(.semibold)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}


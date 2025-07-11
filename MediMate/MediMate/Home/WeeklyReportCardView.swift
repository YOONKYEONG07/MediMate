import SwiftUI

struct WeeklyReportCardView: View {
    let weekRange: String
    let successRate: Int
    let isCurrentWeek: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🗓️ \(weekRange)")
                .font(.headline)
            Text("복약 성공률: \(successRate)%")
                .font(.title)
                .bold()

            if successRate == 100 {
                Text("🥇 이번 주 완벽해요!")
                    .foregroundColor(.yellow)
            } else if successRate >= 70 {
                Text("👍 잘하고 있어요!")
                    .foregroundColor(.green)
            } else {
                Text("📌 다음 주는 더 열심히 해봐요!")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200) // ✅ 카드 크기 키움
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrentWeek ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
    }
}

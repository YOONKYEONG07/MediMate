import SwiftUI

struct WeeklyReportCardView: View {
    let weekRange: String
    let successRate: Int
    let isCurrentWeek: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🗓️ \(weekRange)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("복약 성공률: \(successRate)%")
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)

            if successRate == 100 {
                Text("🥇 이번 주 완벽해요!")
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if successRate >= 50 {
                Text("👍 아주 잘하고 있어요!")
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("💊 꾸준히 복용하는게 좋아요!")
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
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


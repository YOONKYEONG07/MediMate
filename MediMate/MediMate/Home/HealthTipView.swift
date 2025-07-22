import SwiftUI

struct HealthTipView: View {
    let tips = [
        "💊 이 약은 반드시 식후에 복용하세요.",
        "🍺 약 복용 후에는 음주를 피하세요.",
        "🥛 약은 충분한 물과 함께 드세요.",
        "🕒 약 복용 시간은 매일 비슷하게 유지하는 게 좋아요.",
        "📦 약은 서늘하고 건조한 곳에 보관하세요.",
        "🚫 같은 성분의 약을 중복 복용하지 마세요.",
        "📝 처방약과 영양제는 함께 복용 전 꼭 확인하세요.",
        "📱 알림 기능을 활용해 복용을 잊지 마세요!"
    ]
    
    // 오늘 날짜 기반으로 랜덤 팁 선택
    var todayTip: String {
        let index = Calendar.current.component(.day, from: Date()) % tips.count
        return tips[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("복약 건강 팁")
                .font(.headline)

            Text(todayTip)
                .font(.body)
                .padding(10)
                .background(Color(.systemGreen).opacity(0.1))
                .cornerRadius(14)
        }
        .padding()  // 내부 여백
        .frame(maxWidth: .infinity, alignment: .leading)  // 박스 폭 최대 + 왼쪽 정렬
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)  // 외부 좌우 여백 통일
    }
}

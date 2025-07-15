import SwiftUI

struct HealthQuestionCard: View {
    let question: HealthQuestion
    let onTap: () -> Void

    var body: some View {
        // ✅ 안쪽 콘텐츠
        VStack(alignment: .leading, spacing: 8) {
            Text("💬 오늘의 건강 궁금증")
                .font(.headline)

            Text("“\(question.question)”")
                .font(.subheadline)

            Button(action: onTap) {
                Text("AI 약사에게 물어보기 →")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding()  // ⬅️ 안쪽 여백

        // ✅ 바깥 박스와 여백 처리 (중요!)
        .frame(maxWidth: .infinity)  // ⬅️ 박스를 좌우 끝까지 확장
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))  // 동일한 회색
        )
        .padding(.horizontal)  // ⬅️ 외부 여백 (복약 건강 팁과 동일하게)
    }
}

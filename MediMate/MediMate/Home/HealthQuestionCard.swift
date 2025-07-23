import SwiftUI

struct HealthQuestionCard: View {
    let question: HealthQuestion
    let onTap: () -> Void

    var body: some View {
        HStack {
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
            Spacer() // 왼쪽 정렬 고정
        }
        .padding()  // 콘텐츠 내부 여백
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

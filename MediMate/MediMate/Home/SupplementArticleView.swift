import SwiftUI

struct SupplementArticleView: View {
    var supplementName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("\(supplementName) 관련 정보")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("📰 이곳에 \(supplementName)에 대한 기사, 설명, 부작용, 성분 정보 등을 표시할 수 있어요.")
                    .font(.body)
                    .foregroundColor(.secondary)

                // 예: 실제 API 연동하거나 Firestore에서 정보 불러올 수 있음
            }
            .padding()
        }
        .navigationTitle(supplementName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

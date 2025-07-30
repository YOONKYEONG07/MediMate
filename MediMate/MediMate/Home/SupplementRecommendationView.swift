import SwiftUI

// 📘 아티클 모델
struct SupplementArticle: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
}

// 📗 더미 데이터 (원하면 Firestore 연동도 가능)
let supplementArticles: [SupplementArticle] = [
    SupplementArticle(title: "비타민 B", summary: "피로 회복에 효과적이며, 신경 건강에 도움을 줍니다."),
    SupplementArticle(title: "비타민 C", summary: "면역력 강화에 필수적인 영양소입니다."),
    SupplementArticle(title: "오메가3", summary: "혈액순환 및 두뇌 건강에 도움을 줍니다."),
    SupplementArticle(title: "철분제", summary: "빈혈 예방에 효과적인 영양제입니다."),
    SupplementArticle(title: "마그네슘", summary: "근육 경련 완화 및 스트레스 해소에 도움을 줍니다.")
]

struct SupplementRecommendationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 🟩 건강 상태 체크 카드
                HealthSurveyStartCard()

                // 📄 아티클 섹션 타이틀
                Text("추천 영양제 아티클")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                // 📄 아티클 카드 리스트
                ForEach(supplementArticles) { article in
                    SupplementArticleCard(article: article)
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("맞춤 영양제 추천")
    }
}


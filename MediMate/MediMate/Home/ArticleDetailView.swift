import SwiftUI

struct ArticleDetailView: View {
    let article: SupplementArticle
    @Binding var selectedTab: Int
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 🟦 제목 + 요약 (padding 필요)
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.largeTitle)
                        .bold()
                    
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        selectedTab = 3 // ← "상담" 탭 index
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("💬 AI 상담 챗봇에게 물어보기 →")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    
                    Button {
                        selectedTab = 0
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("🏠 홈으로 돌아가기")
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                // 🟪 섹션별 카드
                section("✅ 기본 설명", content: article.overview)
                section("💪 효능", bulletList: article.effects)
                section("💊 복용법", bulletList: article.method)
                section("⚠️ 주의사항", bulletList: article.caution)
                section("🔄 상호작용", bulletList: article.interaction)
            }
            .padding(.horizontal) // ✅ 여기만 좌우 여백 적용
            .padding(.top)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 🔷 텍스트 단락용 섹션
    @ViewBuilder
    func section(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(width: 360, alignment: .leading) // ✅ 원하는 고정폭으로 맞춰줌
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .center) // ✅ 중앙 정렬
    }
    
    // 🔷 리스트 항목용 섹션
    @ViewBuilder
    func section(_ title: String, bulletList: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(bulletList, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .padding(.top, 2)
                        Text(item)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(width: 360, alignment: .leading) // ✅ 고정된 넓이
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .center) // ✅ 중앙 정렬
    }
}

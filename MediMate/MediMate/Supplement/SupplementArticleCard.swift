import SwiftUI

struct SupplementArticleCard: View {
    let article: SupplementArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.headline)

            Text(article.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)

            NavigationLink(destination: ArticleDetailView(article: article)) {
                Text("자세히 보기")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

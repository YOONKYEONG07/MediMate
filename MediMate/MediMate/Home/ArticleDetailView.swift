import SwiftUI

struct ArticleDetailView: View {
    let article: SupplementArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.largeTitle)
                    .bold()

                Text(article.summary)
                    .font(.body)

                Divider()

                Text("상세 설명은 추후 작성 예정입니다.")
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .navigationTitle(article.title)
    }
}

//test ver.

import SwiftUI

struct SupplementResultView: View {
    let resultText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("✅ Top 5 추천 영양제")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("당신의 건강 상태에 맞춘 추천입니다.\n카드를 눌러 관련 정보를 확인해보세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                ForEach(topRecommendations, id: \.self) { item in
                    NavigationLink(destination: SupplementArticleView(supplementName: item.title)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(item.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("추천 결과")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Top 5 추출
    var topRecommendations: [Recommendation] {
        let all = parseRecommendations(from: resultText)
        return Array(all.prefix(5))
    }

    // MARK: - 텍스트 파싱
    func parseRecommendations(from text: String) -> [Recommendation] {
        let blocks = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        var results: [Recommendation] = []

        for block in blocks {
            if let titleStart = block.range(of: "**"),
               let titleEnd = block.range(of: "**", range: titleStart.upperBound..<block.endIndex) {
                let title = String(block[titleStart.upperBound..<titleEnd.lowerBound])
                let description = String(block[titleEnd.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                results.append(Recommendation(title: title, description: description))
            }
        }

        return results
    }
}

struct Recommendation: Hashable {
    let title: String
    let description: String
}

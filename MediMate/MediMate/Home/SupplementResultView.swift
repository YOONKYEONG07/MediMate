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

                // 🔹 카드 리스트
                ForEach(topRecommendations, id: \.self) { item in
                    SupplementCardView(item: item)
                }
            }
            .padding()
        }
        .navigationTitle("추천 결과")
        .navigationBarTitleDisplayMode(.inline)
    }

    // ✅ Top 5 추출
    var topRecommendations: [Recommendation] {
        let all = parseRecommendations(from: resultText)
        return Array(all.prefix(5))
    }

    // ✅ 텍스트 파싱
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

// ✅ Recommendation 구조체
struct Recommendation: Hashable {
    let title: String
    let description: String

    var splitNames: [String] {
        title.components(separatedBy: "와")
            .flatMap { $0.components(separatedBy: "과") }
            .map { $0.replacingOccurrences(of: " ", with: "") }
    }
}

// ✅ 카드 뷰
struct SupplementCardView: View {
    let item: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 각 이름 보여주기 + 첫 매칭된 이름에만 NavigationLink
            if let firstMatched = item.splitNames.compactMap({ matchToKnownSupplement($0) }).first {
                NavigationLink(destination: SupplementArticleView(supplementName: firstMatched)) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(item.splitNames, id: \.self) { name in
                            HStack {
                                Text("👉 \(name)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }

                        Text(item.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                }
            } else {
                // 매칭 안 되면 그냥 보여주기만
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.splitNames, id: \.self) { name in
                        HStack {
                            Text("👉 \(name)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }

                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            }
        }
    }
}

// ✅ 이름 매칭 함수 (전역에 선언)
func matchToKnownSupplement(_ rawName: String) -> String? {
    let knownSupplements = [
        "밀크시슬", "오메가-3 지방산", "콜라겐 보충제",
        "비타민D", "비오틴", "프로바이오틱스", "마그네슘", "비타민C", "비타민B",
        "철분과 엽산", "알파 리포산", "종합비타민", "코엔자임 Q10"
    ]
    
    let normalizedName = rawName
            .replacingOccurrences(of: "씨슬", with: "시슬")
            .replacingOccurrences(of: "콤플렉스", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
    
    for name in knownSupplements {
        if rawName.contains(name.replacingOccurrences(of: " ", with: "")) {
            return name
        }
    }

    return nil
}

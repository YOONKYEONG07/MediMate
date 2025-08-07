import SwiftUI

struct SupplementResultView: View {
    let resultText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("✅ Top 5 추천 영양제")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("⚠️ 본 영양제 추천은 일반적인 건강 상태를 기준으로 제공됩니다.\n개인 복용 여부는 반드시 전문가와 상담 후 결정해주세요.")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.leading)

                if topRecommendations.isEmpty {
                    Text("❌ 추천 결과가 없어요.\nGPT 응답 포맷을 확인해주세요.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    ForEach(topRecommendations, id: \.self) { item in
                        SupplementCardView(item: item)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("추천 결과")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    var topRecommendations: [Recommendation] {
        let all = parseNewStyleRecommendations(from: resultText)
        return Array(all.prefix(5))
    }

    // ✅ 새로운 형식 파싱
    func parseNewStyleRecommendations(from text: String) -> [Recommendation] {
        let blocks = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        var results: [Recommendation] = []

        for block in blocks {
            let lines = block.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

            guard lines.count >= 2 else { continue }

            let firstLine = lines[0]
            guard let catStart = firstLine.range(of: "**"),
                  let catEnd = firstLine.range(of: "**", range: catStart.upperBound..<firstLine.endIndex) else { continue }

            let category = String(firstLine[catStart.upperBound..<catEnd.lowerBound])

            // 첫 줄의 나머지에서 "추천드립니다." 이전까지를 이름처럼 추출
            let remainingLine = String(firstLine[catEnd.upperBound...])
            let name = extractSupplementName(from: remainingLine)

            // 설명은 2번째 줄부터 합쳐서 하나의 문장으로
            let description = lines.dropFirst().joined(separator: " ")

            results.append(Recommendation(category: category, name: name, description: description))
        }

        return results
    }

    // ✅ "루테인과 제아잔틴이 포함된 ..." → "루테인과 제아잔틴"
    func extractSupplementName(from text: String) -> String {
        if let range = text.range(of: "이 포함") {
            return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        } else if let range = text.range(of: "가 포함") {
            return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        } else if let range = text.range(of: "이 들어") {
            return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return "추천 영양제"
    }
}

// ✅ 모델
struct Recommendation: Hashable {
    let category: String
    let name: String
    let description: String
}

// ✅ 카드 UI
struct SupplementCardView: View {
    let item: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("👉 \(item.category)")
                .font(.subheadline)
                .foregroundColor(.blue)

            Text("- \(item.name): \(item.description)")
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

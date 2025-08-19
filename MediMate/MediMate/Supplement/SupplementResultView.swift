import SwiftUI

struct SupplementResultView: View {
    let resultText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("✅ 추천 맞춤 영양제")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("⚠️ 영양제 섭취 전 의료 전문가와의 상담을 권장합니다.")
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

    // ✅ 새로운 형식(👉 카테고리 / - 이름: 설명) 우선 파싱 + 백업(**카테고리** …)
    func parseNewStyleRecommendations(from text: String) -> [Recommendation] {
        var results: [Recommendation] = []
        var currentCategory: String = "추천"

        // 줄 단위 스캔
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for line in lines {
            // 1) 👉 카테고리
            if line.hasPrefix("👉") {
                let cat = line.dropFirst(1).trimmingCharacters(in: .whitespaces)
                currentCategory = cat
                continue
            }

            // 2) - 이름: 설명
            if line.hasPrefix("- ") {
                let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)

                // 콜론이 없는 경우 → 이름 없이 설명만
                if !content.contains(":") {
                    results.append(Recommendation(category: currentCategory, name: "", description: content))
                } else if let colon = content.firstIndex(of: ":") {
                    let namePart = content[..<colon].trimmingCharacters(in: .whitespaces)
                    let descPart = content[content.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                    results.append(Recommendation(category: currentCategory, name: namePart, description: descPart))
                }
                continue
            }

            // 3) 백업: "**카테고리** ..." 한 줄 + 다음 줄들 설명
            if line.contains("**") {
                if let catStart = line.range(of: "**"),
                   let catEnd = line.range(of: "**", range: catStart.upperBound..<line.endIndex) {
                    let category = String(line[catStart.upperBound..<catEnd.lowerBound])
                    let remaining = String(line[catEnd.upperBound...]).trimmingCharacters(in: .whitespaces)
                    let name = extractSupplementName(from: remaining)
                    let desc = remaining.isEmpty ? "설명 참고" : remaining
                    results.append(Recommendation(category: category.isEmpty ? currentCategory : category,
                                                  name: name,
                                                  description: desc))
                }
            }
        }

        return results
    }

    func extractSupplementName(from text: String) -> String {
        let cutWords = ["이 포함", "가 포함", "이 들어", "가 들어", "를 포함", "을 포함"]
        for key in cutWords {
            if let range = text.range(of: key) {
                return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
        }
        if let colon = text.firstIndex(of: ":") {
            return String(text[..<colon]).trimmingCharacters(in: .whitespaces)
        }
        return text.isEmpty ? "" : text
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

            if item.name.isEmpty {
                Text("- \(item.description)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("- \(item.name): \(item.description)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

struct RecItem: Codable, Identifiable {
    let id = UUID()
    var category: String
    var name: String
    var description: String
}

// 파싱 후 호출해 주세요: let cleaned = mergeOrphanDescriptions(items)
func mergeOrphanDescriptions(_ items: [RecItem]) -> [RecItem] {
    var out: [RecItem] = []
    var lastIndex: Int? = nil

    func trim(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cleanedName(_ s: String) -> String {
        // 불릿/기호/콜론 제거
        var t = trim(s)
        t = t.replacingOccurrences(of: #"^[-•👉\s]*"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"^\:\s*"#, with: "", options: .regularExpression)
        return t
    }

    for var it in items {
        it.category     = trim(it.category)
        it.name         = cleanedName(it.name)
        it.description  = trim(it.description)

        let genericCat = it.category.isEmpty || ["추천", "기타", "-", "추천 항목"].contains(it.category)
        let descOnly   = (it.name.isEmpty || it.name == "-" || it.name == "추천 항목") && !it.description.isEmpty

        // ① 설명만 있는 행이거나, 제네릭 카테고리로 설명이 온 경우 → 직전 항목으로 병합
        if let li = lastIndex, (descOnly || (genericCat && !it.description.isEmpty && it.name.isEmpty)) {
            if out[li].description.isEmpty {
                out[li].description = it.description
            } else {
                out[li].description += "\n" + it.description
            }
            continue
        }

        // ② 이름만 있는 행(설명은 비어 있음) → 일단 넣고 다음 설명을 기다림
        out.append(it)
        lastIndex = out.count - 1
    }

    return out
}

// ChatGPTService.swift (교체)
import Foundation

private let REQUIRED_PREFIX = "선택한 카테고리:"
private let REQUIRED_FIELDS = ["요약", "핵심", "답변", "주의"]

final class ChatGPTService {
    static let shared = ChatGPTService()

    // ⚠️ 실제 배포에선 키를 코드 밖으로 빼세요.
    private let apiKey = " "
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func sendMessage(messages: [String],
                     selectedCategory: ChatCategory,
                     completion: @escaping (String?) -> Void) {

        let system = """
        너는 한국어로 답하는 약사 챗봇이다.
        반드시 아래 규칙을 지켜라.

        \(selectedCategory.guardrail)

        출력 형식(반드시 그대로):
        \(REQUIRED_PREFIX) \(selectedCategory.rawValue)

        *요약:* 한 줄

        # 핵심
        - 불릿 3–6개 (카테고리 범위 안에서만)

        # 답변
        2–5문단. 과도한 장황 금지. 모르면 모른다고 말해라.

        # 주의
        - 위험 신호/병원 내원 기준이 있으면 간단히.
        - 개인 맞춤 상담은 실제 전문가와 상의하도록 유도.

        
        """

        var chatMessages: [[String: String]] = [
            ["role": "system", "content": system]
        ]
        for m in messages {
            chatMessages.append(["role": "user", "content": m])
        }

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "temperature": 0.2,
            "top_p": 0.9,
            "messages": chatMessages
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data, error == nil else { completion(nil); return }
            let content = Self.parseContent(data)
            let safe = self.enforceCategoryFormat(content, category: selectedCategory.rawValue)
            completion(safe)
        }.resume()
    }

    private static func parseContent(_ data: Data) -> String {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { return "" }
        return content
    }

    private func enforceCategoryFormat(_ raw: String, category: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.hasPrefix("\(REQUIRED_PREFIX) \(category)") {
            // 범위 벗어남 경고 문구가 오면 그대로 내보내되 머리 붙임
            if text.contains("범위를 벗어납니다") {
                return "\(REQUIRED_PREFIX) \(category)\n\n\(text)"
            }
            text = "\(REQUIRED_PREFIX) \(category)\n\n" + text
        }
        let hasRequired = REQUIRED_FIELDS.contains { text.contains($0) }
        if !hasRequired {
            text = """
            \(REQUIRED_PREFIX) \(category)

            **요약:** \(firstLine(from: text))

            ## 핵심
            - \(bulletize(from: text, max: 4).joined(separator: "\n- "))

            ## 답변
            \(text)

            ## 주의
            - 개인 상황에 따라 달라질 수 있어요. 복약은 전문가와 상의해 주세요.
            """
        }
        return normalizeSpacing(text)
    }

    private func firstLine(from s: String) -> String {
        s.split(separator: "\n").first.map(String.init) ?? "요약 정보를 제공해요."
    }

    private func bulletize(from s: String, max: Int) -> [String] {
        let parts = s
            .replacingOccurrences(of: "•", with: "-")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix(REQUIRED_PREFIX) && !$0.hasPrefix("##") }
        return Array(parts.prefix(max)).map {
            var t = $0; if t.hasPrefix("- ") { t.removeFirst(2) }; return t
        }
    }

    private func normalizeSpacing(_ s: String) -> String {
        let lines = s.replacingOccurrences(of: "\r", with: "\n").components(separatedBy: "\n")
        var out: [String] = []
        var prevEmpty = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isEmpty = trimmed.isEmpty
            if !(isEmpty && prevEmpty) { out.append(trimmed) }
            prevEmpty = isEmpty
        }
        return out.joined(separator: "\n")
    }
}


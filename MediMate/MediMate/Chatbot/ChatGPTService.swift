import Foundation

class ChatGPTService {
    static let shared = ChatGPTService()

    // ❗️주의: 실제 프로젝트에서는 이 키를 .xcconfig나 Info.plist 등으로 분리해야 보안에 안전합니다.
    private let apiKey = "" // ✅ 너의 OpenAI API Key 입력

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    /// ✅ 1. ChatGPT 메시지 전송
    func sendMessage(messages: [String], completion: @escaping (String?) -> Void) {
        var chatMessages: [[String: String]] = [
            ["role": "system", "content": "당신은 약사입니다. 사용자 질문에 친절하고 정확하게 답변해 주세요."]
        ]

        for message in messages {
            chatMessages.append(["role": "user", "content": message])
        }

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": chatMessages
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(nil)
            return
        }

        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {

                // ✅ 2. 자동 줄바꿈 형식 적용
                let formatted = self.formatChatbotResponse(content)
                completion(formatted)

            } else {
                completion(nil)
            }
        }.resume()
    }

    /// ✅ 줄바꿈 포함한 포맷팅 함수
    private func formatChatbotResponse(_ response: String) -> String {
        let sentences = response.components(separatedBy: ". ")
        let formatted = sentences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: ".\n\n")

        return formatted
    }
}

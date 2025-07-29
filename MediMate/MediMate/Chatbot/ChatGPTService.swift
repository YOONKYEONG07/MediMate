import Foundation

class ChatGPTService {
    static let shared = ChatGPTService()

    private let apiKey = "" // 👉 여기에 네 실제 키 입력
    // 실제 키는 이곳에 입력하세요.
    // API 키는 Git에 올리지 말고 로컬에만 보관하세요.

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func sendMessage(messages: [String], completion: @escaping (String?) -> Void) {
        var chatMessages: [[String: String]] = [
            ["role": "system", "content": "당신은 약사입니다. 사용자 질문에 친절하고 정확하게 답변해 주세요."]
        ]

        for message in messages {
            chatMessages.append(["role": "user", "content": message])
        }

        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",
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
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                completion(nil)
            }
        }.resume()
    }
}


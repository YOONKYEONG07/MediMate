import Foundation

class SupplementGPTService {
    static let shared = SupplementGPTService()
    private let apiKey = "" // ✅ 여기 꼭 지워
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func sendRecommendationPrompt(prompt: String, completion: @escaping (String?) -> Void) {
        let messages: [[String: String]] = [
            ["role": "system", "content": "당신은 건강 설문을 바탕으로 영양제를 추천해주는 전문가입니다. 사용자가 작성한 설문을 기반으로 적절한 영양제를 추천하고 이유를 설명해주세요."],
            ["role": "user", "content": prompt]
        ]

        let payload: [String: Any] = [
            "model": "gpt-4o", // 또는 "gpt-3.5-turbo"
            "messages": messages
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

                // ✅ 포맷 줄바꿈
                let formatted = self.formatChatbotResponse(content)
                completion(formatted)

            } else {
                completion(nil)
            }
        }.resume()
    }

    private func formatChatbotResponse(_ response: String) -> String {
        let sentences = response.components(separatedBy: ". ")
        return sentences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: ".\n\n")
    }
}

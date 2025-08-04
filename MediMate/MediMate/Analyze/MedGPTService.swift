import Foundation

class MedGPTService {
    static let shared = MedGPTService()
    private let apiKey = "" // 🔐 실제 키로 바꿔줘

    private init() {}
    
    func fetchSupplementInfoFromGPT(query: String, completion: @escaping ([String: String]) -> Void) {
        fetchGPTInfo(for: query) { result in
            switch result {
            case .success(let info):
                completion(info)
            case .failure(_):
                completion(["효능": "AI 정보를 불러오지 못했습니다."])
            }
        }
    }

    func fetchGPTInfo(for medName: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        let prompt = """
        다음 영양제 또는 의약품 '\(medName)'에 대해 아래 항목들을 각각 간결하게 정리해줘:

        - 효능
        - 복용법
        - 주의사항
        - 상호작용
        - 보관법

        형식은 반드시 아래처럼 key-value JSON으로 응답해줘:
        {
            "효능": "...",
            "복용법": "...",
            "주의사항": "...",
            "상호작용": "...",
            "보관법": "..."
        }
        """

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "너는 전문 약사로서, 의약품과 영양제에 대한 정보를 제공해야 해."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String
            else {
                completion(.failure(NSError(domain: "GPT", code: -1, userInfo: [NSLocalizedDescriptionKey: "응답 파싱 실패"])))
                return
            }

            print("🔍 GPT 응답:\n\(content)")

            if let parsed = try? JSONSerialization.jsonObject(with: Data(content.utf8)) as? [String: String] {
                completion(.success(parsed))
            } else {
                // fallback: 응답은 왔지만 JSON 형식이 아닐 경우
                completion(.success([
                    "효능": content,
                    "복용법": "",
                    "주의사항": "",
                    "상호작용": "",
                    "보관법": ""
                ]))
            }
        }.resume()
    }
}

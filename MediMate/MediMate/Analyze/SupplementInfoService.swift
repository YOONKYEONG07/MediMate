import Foundation

class SupplementInfoService {
    static let shared = SupplementInfoService()
    private init() {}

    private let apiKey = "498df0fbefde4d839178"
    private let baseURL = "https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo02/getFoodNtrCpntDbList02"

    // ⭐️ 영양제 정보 가져오기
    func fetchSupplementInfo(ingredient: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        guard let encoded = ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?serviceKey=\(apiKey)&type=json&pageNo=1&numOfRows=1&prdlst_Nm=\(encoded)")
        else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SupplementAPIResponse.self, from: data)
                if let item = decoded.body?.items?.first {
                    var result: [String: String] = [:]
                    result["제품명"] = item.productName ?? "-"
                    result["제조사"] = item.manufacturer ?? "-"
                    result["기능성"] = item.primaryFunction ?? "-"
                    result["복용법"] = item.intakeMethod ?? "-"
                    result["주의사항"] = item.precaution ?? "-"
                    result["보관법"] = item.storageMethod ?? "-"
                    completion(.success(result))
                } else {
                    completion(.success([:])) // ✅ 빈 경우
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

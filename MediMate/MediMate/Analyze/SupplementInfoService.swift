import Foundation

class SupplementInfoService {
    static let shared = SupplementInfoService()
    private init() {}

    private let apiKey = "498df0fbefde4d839178"
    private let baseURL = "https://apis.data.go.kr/B190001/kfdaAuthIngrdPrdlstInfoService01/getKfdaAuthIngrdPrdlstInfoList01"

    func fetchSupplementInfo(ingredient: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        guard let encodedQuery = ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?serviceKey=\(apiKey)&type=json&numOfRows=3&pageNo=1&RAWMTRL_NM=\(encodedQuery)")
        else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let body = (json["body"] as? [String: Any]),
                   let items = body["items"] as? [[String: Any]],
                   let first = items.first {
                    
                    var result: [String: String] = [:]
                    result["원료명"] = first["RAWMTRL_NM"] as? String ?? "-"
                    result["기능성내용"] = first["FUNC"] as? String ?? "-"
                    result["섭취시 주의사항"] = first["IFTKN_ATNT_MATR_CN"] as? String ?? "-"
                    
                    completion(.success(result))
                } else {
                    completion(.failure(NSError(domain: "No result", code: -3)))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}


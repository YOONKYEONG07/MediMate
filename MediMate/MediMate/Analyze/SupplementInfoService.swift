import Foundation

class SupplementInfoService {
    static let shared = SupplementInfoService()
    private init() {}

    // 🔹 기존 건강기능식품 API (개별인정형)
    private let healthFuncAPIKey = "498df0fbefde4d839178"
    private let healthFuncBaseURL = "https://apis.data.go.kr/B190001/kfdaAuthIngrdPrdlstInfoService01/getKfdaAuthIngrdPrdlstInfoList01"

    // 🔹 새로 등록한 식품영양성분DB API
    private let nutritionAPIKey = "4mOQmFtXFTj06luhDNrGl6zcLWKGC…(생략)…8vPSwrKT0hUw%3D"
    private let nutritionBaseURL = "https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo02"

    // 🔍 단순 키워드로 영양소 여부 판별
    private func isNutritionKeyword(_ keyword: String) -> Bool {
        let keywords = ["비타민", "미네랄", "칼슘", "아연", "철분", "엽산", "마그네슘", "오메가", "비오틴", "루테인", "코엔자임", "라이코펜", "셀레늄"]
        return keywords.contains { keyword.localizedCaseInsensitiveContains($0) }
    }

    // 🔁 통합 진입점
    func fetchSupplementInfo(ingredient: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        if isNutritionKeyword(ingredient) {
            // 1차 시도: nutritionDB
            fetchFromNutritionDB(ingredient: ingredient) { result in
                switch result {
                case .success(let info):
                    if info.isEmpty {
                        // nutritionDB에 정보 없으면 → healthFuncAPI로 fallback
                        self.fetchFromHealthFuncAPI(ingredient: ingredient, completion: completion)
                    } else {
                        completion(.success(info))
                    }
                case .failure:
                    // 실패해도 → healthFuncAPI로 fallback
                    self.fetchFromHealthFuncAPI(ingredient: ingredient, completion: completion)
                }
            }
        } else {
            // 1차 시도: healthFuncAPI
            fetchFromHealthFuncAPI(ingredient: ingredient) { result in
                switch result {
                case .success(let info):
                    if info.isEmpty {
                        // healthFuncAPI에 없으면 → nutritionDB fallback
                        self.fetchFromNutritionDB(ingredient: ingredient, completion: completion)
                    } else {
                        completion(.success(info))
                    }
                case .failure:
                    // 실패해도 → nutritionDB fallback
                    self.fetchFromNutritionDB(ingredient: ingredient, completion: completion)
                }
            }
        }
    }


    // ✅ 기존 API - 건강기능식품 개별인정형
    private func fetchFromHealthFuncAPI(ingredient: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        guard let encoded = ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(healthFuncBaseURL)?serviceKey=\(healthFuncAPIKey)&type=json&numOfRows=3&pageNo=1&RAWMTRL_NM=\(encoded)")
        else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2))); return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let body = json["body"] as? [String: Any],
                   let items = body["items"] as? [[String: Any]] {

                    if let first = items.first {
                        var result: [String: String] = [:]
                        result["원료명"] = first["RAWMTRL_NM"] as? String ?? "-"
                        result["기능성내용"] = first["FUNC"] as? String ?? "-"
                        result["섭취시 주의사항"] = first["IFTKN_ATNT_MATR_CN"] as? String ?? "-"
                        completion(.success(result))
                    } else {
                        // ✅ 빈 결과 처리
                        completion(.success([:]))
                    }

                } else {
                    completion(.failure(NSError(domain: "No result", code: -3)))
                }

            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // ✅ 새 API - 식품영양성분DB (성분 중심)
    private func fetchFromNutritionDB(ingredient: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        guard let encoded = ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(nutritionBaseURL)?serviceKey=\(nutritionAPIKey)&type=json&pageNo=1&numOfRows=1&cpnt_Nm=\(encoded)")
        else {
            completion(.failure(NSError(domain: "Invalid Nutrition URL", code: -10)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No nutrition data", code: -11))); return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let body = json["body"] as? [String: Any],
                   let items = body["items"] as? [[String: Any]] {

                    if let first = items.first {
                        var result: [String: String] = [:]
                        result["영양소명"] = first["CPNT_NM"] as? String ?? "-"
                        result["영양소기능"] = first["CPNT_FUNC"] as? String ?? "-"
                        result["권장섭취량"] = first["NTK_RECO"] as? String ?? "-"
                        result["상한섭취량"] = first["MAX_IN"] as? String ?? "-"
                        result["결핍증상"] = first["DSRPSN"] as? String ?? "-"
                        completion(.success(result))
                    } else {
                        // ✅ 결과 없으면 빈 값으로 반환
                        completion(.success([:]))
                    }

                } else {
                    completion(.failure(NSError(domain: "No nutrition result", code: -12)))
                }

            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

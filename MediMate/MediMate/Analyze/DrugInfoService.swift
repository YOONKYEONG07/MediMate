import Foundation

class DrugInfoService {
    static let shared = DrugInfoService()

    func fetchDrugInfo(drugName: String, completion: @escaping (DrugInfo?) -> Void) {
        print("🚀 약 이름으로 정보 요청 시작: \(drugName)")

        let encodedName = drugName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://apis.data.go.kr/1471000/DrbEasyDrugInfoService/getDrbEasyDrugList?serviceKey=\(apiKey)&itemName=\(encodedName)&type=json"

        print("📡 최종 URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ URL 생성 실패")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ 요청 중 에러 발생: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ 데이터 없음")
                completion(nil)
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DrugAPIResponse.self, from: data)
                let items = decoded.body.items
                print("✅ 응답 디코딩 성공, 총 개수: \(items.count)")

                let sorted = items.sorted {
                    if $0.itemName == drugName { return true }
                    if $1.itemName == drugName { return false }

                    if $0.itemName?.contains("\(drugName)정") == true { return true }
                    if $1.itemName?.contains("\(drugName)정") == true { return false }

                    return false
                }

                if let bestMatch = sorted.first {
                    completion(bestMatch)
                } else {
                    completion(nil)
                }

            } catch {
                print("❌ 디코딩 실패: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("📄 응답 원문: \(raw)")
                }
                completion(nil)
            }
        }.resume()
    }
}

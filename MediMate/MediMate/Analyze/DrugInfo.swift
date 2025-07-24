import Foundation

// 🔑 API 인증키 (Encoding 키를 넣어주세요)
let apiKey = "4mOQmFtXFTj06luhDNrGl6zcLWKGCGz%2FynnkPw3%2FBzSoZkBZmLWMP0BowPTGEoY8HzCkM4iAAw8vPSwrKT0hUw%3D%3D"

struct DrugInfoResponse: Codable {
    let body: DrugInfoBody
}

struct DrugInfoBody: Codable {
    let items: [DrugInfo]
}

struct DrugInfo: Codable {
    let entpName: String?        // 제조사
    let itemName: String?        // 약 이름
    let efcyQesitm: String?      // 효능
    let useMethodQesitm: String? // 복용법
    let atpnQesitm: String?      // 주의사항
    let intrcQesitm: String?     // 상호작용
    let seQesitm: String?        // 부작용
    let depositMethodQesitm: String? // 보관법
    let itemImage: String?       // 이미지 URL
    let atpnWarnQesitm: String?

}


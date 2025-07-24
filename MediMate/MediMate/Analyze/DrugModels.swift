import Foundation

// ✅ 1. 전체 응답 구조
struct DrugAPIResponse: Codable {
    let body: DrugBody
}

struct DrugBody: Codable {
    let items: [DrugInfo]
}

// ✅ 2. 실제 약 정보 구조
struct MedicineInfo: Codable {
    let itemName: String?
    let entpName: String?
    let efcyQesitm: String?
    let useMethodQesitm: String?
    let atpnWarnQesitm: String?
    let atpnQesitm: String?
    let intrcQesitm: String?
    let seQesitm: String?
    let depositMethodQesitm: String?
}

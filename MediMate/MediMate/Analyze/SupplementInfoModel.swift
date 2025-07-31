import Foundation

struct SupplementAPIResponse: Decodable {
    let body: SupplementBody?

    struct SupplementBody: Decodable {
        let items: [SupplementItem]?

        enum CodingKeys: String, CodingKey {
            case items = "item"
        }
    }
}

struct SupplementItem: Decodable, Identifiable {
    var id: UUID { UUID() }

    let productName: String?       // 제품명
    let manufacturer: String?      // 제조사
    let primaryFunction: String?   // 효능 (기능성)
    let intakeMethod: String?      // 복용법 (섭취방법)
    let precaution: String?        // 주의사항
    let interaction: String?       // 상호작용 (→ 아직 API 필드 없음)
    let storageMethod: String?     // 보관법

    enum CodingKeys: String, CodingKey {
        case productName     = "PRDLST_NM"     // 제품명
        case manufacturer    = "BSSH_NM"       // 제조사
        case primaryFunction = "PRIMARY_FNCLTY"// 기능성
        case intakeMethod    = "NTK_MTHD"      // 섭취방법
        case precaution      = "FRMLC_MTRAL"   // 섭취 시 주의사항
        case interaction     = "IFTKN_ATNT_MATR_CN" // 상호작용 주의사항
        case storageMethod   = "STORAGE_METHOD" // 보관법 (있으면 사용)
    }
}

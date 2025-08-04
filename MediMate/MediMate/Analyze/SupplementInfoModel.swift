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
    let primaryFunction: String?   // 기능성
    let intakeMethod: String?      // 복용법
    let precaution: String?        // 주의사항
    let storageMethod: String?     // ✅ 여기가 새로 추가됨

    enum CodingKeys: String, CodingKey {
        case productName     = "PRDLST_NM"
        case manufacturer    = "BSSH_NM"
        case primaryFunction = "PRIMARY_FNCLTY"
        case intakeMethod    = "NTK_MTHD"
        case precaution      = "FRMLC_MTRAL"
        case storageMethod   = "STORAGE_METHOD" // ✅ API에 필드가 존재한다면 이렇게 연결
    }
}

import Foundation

struct SupplementAPIResponse: Decodable {
    let body: SupplementBody?
    
    struct SupplementBody: Decodable {
        let items: [SupplementInfo]?
        
        enum CodingKeys: String, CodingKey {
            case items = "item"
        }
    }
}

struct SupplementInfo: Decodable {
    let prdlstNm: String?        // 제품명
    let rawmtrl: String?         // 원재료
    let ntkMthd: String?         // 섭취방법
    let primaryFnclty: String?   // 주된 기능성
    let frmlcMatter: String?     // 섭취 시 주의사항
    let capacity: String?        // 섭취량
    let storageMethod: String?   // 보관법

    enum CodingKeys: String, CodingKey {
        case prdlstNm = "PRDLST_NM"
        case rawmtrl = "RAWMTRL"
        case ntkMthd = "NTK_MTHD"
        case primaryFnclty = "PRIMARY_FNCLTY"
        case frmlcMatter = "FRMLC_MTRAL"
        case capacity = "CAPACITY"
        case storageMethod = "STORAGE_METHOD"
    }
}

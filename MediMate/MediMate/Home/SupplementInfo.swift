import Foundation

struct SupplementInfo: Identifiable {
    let id = UUID()
    let name: String        // 영양제 이름
    let function: String    // 기능성 설명
    let caution: String     // 주의사항
    let method: String      // 섭취방법
}

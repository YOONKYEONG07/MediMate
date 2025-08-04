import Foundation

class SupplementMapper {
    static let shared = SupplementMapper()

    private init() {}

    private let nameMap: [String: String] = [
        // MARK: - 루테인 관련
        "루테인": "마리골드꽃추출물",
        "닥터루테인": "루테인",
        "눈건강": "마리골드꽃추출물",

        // MARK: - 비타민C 관련
        "비타민c": "비타민 C",
        "비타민 씨": "비타민 C",
        "비타c": "비타민 C",
        "vitamin c": "비타민 C",

        // MARK: - 비타민D 관련
        "비타민d": "비타민 D",
        "비타d": "비타민 D",
        "vitamin d": "비타민 D",
        "햇빛비타민": "비타민 D",

        // MARK: - 오메가-3 관련
        "오메가3": "오메가-3 지방산",
        "오메가-3": "오메가-3 지방산",
        "피쉬오일": "오메가-3 지방산",
        "fish oil": "오메가-3 지방산",
        "epa dha": "오메가-3 지방산",

        // MARK: - 밀크시슬 관련
        "밀크씨슬": "밀크시슬",
        "간영양제": "밀크시슬",
        "밀크시슬": "밀크시슬",

        // MARK: - 콜라겐 관련
        "콜라겐": "콜라겐 보충제",
        "피쉬콜라겐": "콜라겐 보충제",
        "marine collagen": "콜라겐 보충제",

        // MARK: - 철분 관련
        "철분": "철분과 엽산",
        "철분제": "철분과 엽산",
        "엽산": "철분과 엽산",
        "임산부영양제": "철분과 엽산",

        // MARK: - 비오틴 관련
        "비오틴": "비오틴(비타민 B7)",
        "탈모영양제": "비오틴(비타민 B7)",

        // MARK: - 유산균 관련
        "유산균": "프로바이오틱스",
        "프로바이오틱스": "프로바이오틱스",
        "장영양제": "프로바이오틱스",

        // MARK: - 종합비타민
        "멀티비타민": "멀티비타민",
        "종합비타민": "멀티비타민",
        "비타민종합제": "멀티비타민",

        // MARK: - 항산화
        "코엔자임q10": "코엔자임 Q10",
        "코큐텐": "코엔자임 Q10",
        "q10": "코엔자임 Q10",

        // MARK: - 알파리포산
        "알파리포산": "알파 리포산",
        "alpha lipoic acid": "알파 리포산",

        // MARK: - 마그네슘
        "마그네슘": "마그네슘",
        "근육경련": "마그네슘",
        "magnesium": "마그네슘",

        // MARK: - 아연
        "아연": "아연",
        "면역영양제": "아연",
        "zinc": "아연"
    ]

    /// 사용자 입력을 API용 원재료명으로 매핑
    func mapToIngredient(_ productName: String) -> String {
        var current = productName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var visited = Set<String>()

        while let mapped = nameMap[current], !visited.contains(mapped.lowercased()) {
            visited.insert(current)
            current = mapped.lowercased()
        }

        print("🔍 사용자 입력: \(productName) → 최종 매핑 결과: \(current)")
        return current
    }
}

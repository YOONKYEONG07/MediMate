import Foundation

class SupplementMapper {
    static let shared = SupplementMapper()

    private init() {}

    private let nameMap: [String: String] = [
        // 루테인 관련
        "루테인": "마리골드꽃추출물",
        "닥터루테인": "루테인",
        "눈건강": "마리골드꽃추출물",

        // 비타민C 관련
        "비타민C": "비타민 C",
        "비타민 씨": "비타민 C",
        "비타C": "비타민 C",
        "vitamin c": "비타민 C",

        // 비타민D 관련
        "비타민D": "비타민 D",
        "비타D": "비타민 D",
        "vitamin d": "비타민 D",
        "햇빛비타민": "비타민 D",

        // 오메가-3 관련
        "오메가3": "오메가-3 지방산",
        "오메가-3": "오메가-3 지방산",
        "피쉬오일": "오메가-3 지방산",
        "fish oil": "오메가-3 지방산",
        "EPA DHA": "오메가-3 지방산",

        // 밀크씨슬 관련
        "밀크씨슬": "밀크시슬",
        "간영양제": "밀크시슬",
        "밀크시슬": "밀크시슬",

        // 콜라겐 관련
        "콜라겐": "콜라겐 보충제",
        "피쉬콜라겐": "콜라겐 보충제",
        "marine collagen": "콜라겐 보충제",

        // 철분 관련
        "철분": "철분과 엽산",
        "철분제": "철분과 엽산",
        "엽산": "철분과 엽산",
        "임산부영양제": "철분과 엽산",

        // 비오틴 관련
        "비오틴": "비오틴(비타민 B7)",
        "탈모영양제": "비오틴(비타민 B7)",

        // 유산균/프로바이오틱스 관련
        "유산균": "프로바이오틱스",
        "프로바이오틱스": "프로바이오틱스",
        "장영양제": "프로바이오틱스",

        // 종합비타민
        "멀티비타민": "멀티비타민",
        "종합비타민": "멀티비타민",
        "비타민종합제": "멀티비타민",

        // 항산화/노화방지
        "코엔자임Q10": "코엔자임 Q10",
        "코큐텐": "코엔자임 Q10",
        "Q10": "코엔자임 Q10",

        // 알파리포산
        "알파리포산": "알파 리포산",
        "alpha lipoic acid": "알파 리포산",

        // 마그네슘
        "마그네슘": "마그네슘",
        "근육경련": "마그네슘",
        "magnesium": "마그네슘",

        // 아연
        "아연": "아연",
        "면역영양제": "아연",
        "zinc": "아연"
    ]


    func mapToIngredient(_ productName: String) -> String {
        var current = productName
        var visited = Set<String>()

        while let mapped = nameMap[current], !visited.contains(mapped) {
            visited.insert(current)
            current = mapped
        }

        return current
    }
}


import Foundation

class SupplementMapper {
    static let shared = SupplementMapper()

    private init() {}

    private let nameMap: [String: String] = [
        "닥터루테인": "루테인",
        "루테인": "마리골드꽃추출물",
        "비타민C": "비타민 C",
        "오메가3": "오메가-3 지방산",
        "밀크씨슬": "밀크시슬",
        "멀티비타민": "멀티비타민",
        "비오틴": "비오틴(비타민 B7)"
        // 필요한 항목 더 추가 가능
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


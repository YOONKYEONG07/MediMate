import Foundation

struct MedicationReminder: Identifiable, Codable {
    var id: String
    var name: String
    var hours: [Int]   // ✅ 단일 Int → [Int] 배열로 변경
    var minutes: [Int] // ✅ 단일 Int → [Int] 배열로 변경
    var days: [String]
    var timeDescription: String?
}


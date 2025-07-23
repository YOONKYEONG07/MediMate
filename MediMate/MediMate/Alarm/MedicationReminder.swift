import Foundation

struct MedicationReminder: Identifiable, Codable, Equatable {
    let id: String  // 알림 ID (UUID로 생성)
    let name: String
    let hour: Int
    let minute: Int
    var days: [String]
}

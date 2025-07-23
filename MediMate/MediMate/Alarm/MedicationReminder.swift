import Foundation

struct MedicationReminder: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString// 알림 ID (UUID로 생성)
    var name: String
    var hour: Int
    var minute: Int
    var days: [String]
}

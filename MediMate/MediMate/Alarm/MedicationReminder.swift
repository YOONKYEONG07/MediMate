import Foundation

struct MedicationReminder: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var hours: [Int]
    var minutes: [Int]
    var days: [String]
    var timeDescription: String?
}


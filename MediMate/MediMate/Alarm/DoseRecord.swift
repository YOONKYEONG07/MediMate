import Foundation

struct DoseRecord: Identifiable, Codable {
    let id: String
    let medicineName: String
    let takenTime: Date
    let taken: Bool
}

import Foundation

struct DoseRecord: Identifiable, Codable {
    let id: String
    let medicineName: String
    var takenTime: Date
    var taken: Bool
}

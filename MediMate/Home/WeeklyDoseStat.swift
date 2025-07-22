import Foundation

struct WeeklyDoseStat: Identifiable {
    let id = UUID()
    let weekday: String
    let success: Bool
}

import SwiftUI

struct CalendarGridView: View {
    let records: [DoseRecord]
    let calendar = Calendar.current

    var currentMonth: Date {
        Date()
    }

    var body: some View {
        let daysInMonth = generateCalendarDays()

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
            ForEach(daysInMonth, id: \.self) { date in
                VStack {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.caption)

                    if hasTakenMedication(on: date) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
        }
    }

    func generateCalendarDays() -> [Date] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!

        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: start)
        }
    }

    func hasTakenMedication(on date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return records.contains {
            calendar.isDate($0.takenTime, inSameDayAs: startOfDay)
        }
    }
}

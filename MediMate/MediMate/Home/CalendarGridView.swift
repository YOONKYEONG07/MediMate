import SwiftUI

struct CalendarGridView: View {
    let records: [Date: Bool]
    let currentMonth: Date
    @Binding var selectedDate: Date?

    private var daysInMonth: [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: currentMonth),
              let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }

        return range.compactMap { day in
            Calendar.current.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private func statusColor(for date: Date) -> Color {
        let key = Calendar.current.startOfDay(for: date)
        if let success = records[key] {
            return success ? .green : .red
        } else {
            return .gray.opacity(0.3)
        }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        let today = Calendar.current.startOfDay(for: Date())

        LazyVGrid(columns: columns, spacing: 8) {
            // 요일 헤더
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }

            // 빈칸 채우기
            let firstDay = daysInMonth.first ?? Date()
            let weekdayOffset = Calendar.current.component(.weekday, from: firstDay) - 1
            ForEach(0..<weekdayOffset, id: \.self) { _ in
                Color.clear.frame(height: 28)
            }

            // 날짜 표시
            ForEach(daysInMonth, id: \.self) { date in
                let day = Calendar.current.component(.day, from: date)
                let isToday = Calendar.current.isDate(date, inSameDayAs: today)

                Button(action: {
                    selectedDate = date
                }) {
                    Circle()
                        .fill(statusColor(for: date))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("\(day)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: isToday ? 2 : 0)
                        )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}


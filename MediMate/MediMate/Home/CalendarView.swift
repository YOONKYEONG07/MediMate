import SwiftUI

struct CalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDate: Date? = nil
    let records: [Date: Bool]
    let onDateSelected: (Date) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 🔹 월 이동 헤더
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthTitle(for: currentDate))
                    .font(.title2).bold()
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            Divider()

            // 🔹 달력 본체
            CalendarGridView(
                records: filteredRecords(for: currentDate),
                currentMonth: currentDate,
                selectedDate: $selectedDate
            )

            // 🔹 선택된 날짜의 주간 기록
            if let date = selectedDate {
                let week = weekDates(for: date)

                VStack(alignment: .leading, spacing: 8) {
                    Text("📅 \(formattedDate(date))")
                        .font(.headline)

                    Text("이번 주 기록:")
                        .font(.subheadline)
                        .padding(.top, 4)

                    ForEach(week, id: \.self) { d in
                        let status = records[Calendar.current.startOfDay(for: d)]
                        HStack {
                            Text(formattedShortDate(d))
                            Spacer()
                            Text(recordMessage(for: status))
                                .foregroundColor(status == true ? .green : (status == false ? .red : .gray))
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding()
    }

    // 🔧 유틸 함수들

    func changeMonth(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: currentDate) {
            currentDate = newDate
            selectedDate = nil // 월 바꾸면 선택 해제
        }
    }

    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: date)
    }

    func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }

    func recordMessage(for status: Bool?) -> String {
        switch status {
        case true: return "복용 완료 ✅"
        case false: return "복용 실패 ❌"
        case nil: return "기록 없음 ⚪️"
        @unknown default: return "알 수 없음 ❓"
        }
    }

    func filteredRecords(for date: Date) -> [Date: Bool] {
        guard let range = Calendar.current.dateInterval(of: .month, for: date) else { return [:] }
        return records.filter { range.contains($0.key) }
    }

    func weekDates(for date: Date) -> [Date] {
        guard let weekRange = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: weekRange.start)
        }
    }
}

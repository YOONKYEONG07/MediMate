import SwiftUI

struct WeeklyDetailCard: View {
    @State private var currentWeekStart: Date
    let records: [Date: Bool]

    init(weekStart: Date, records: [Date: Bool]) {
        _currentWeekStart = State(initialValue: weekStart)
        self.records = records
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 🔁 이전 주 / 다음 주 버튼
            HStack {
                Button(action: { moveWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                    Text("이전 주")
                }

                Spacer()

                Text("📅 \(weekDateRangeString(from: currentWeekStart))")
                    .font(.headline)

                Spacer()

                Button(action: { moveWeek(by: 1) }) {
                    Text("다음 주")
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.bottom, 4)

            Divider()

            // 📅 7일간 복약 기록 표시
            ForEach(0..<7, id: \.self) { offset in
                if let date = Calendar.current.date(byAdding: .day, value: offset, to: currentWeekStart) {
                    let status = records[Calendar.current.startOfDay(for: date)]
                    HStack {
                        Text(formattedDate(date))
                        Spacer()
                        Text(recordMessage(for: status))
                            .foregroundColor(status == true ? .green : status == false ? .red : .gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // ✅ 주차 이동 함수
    func moveWeek(by offset: Int) {
        if let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart),
           let startOfNewWeek = Calendar.current.dateInterval(of: .weekOfYear, for: newWeek)?.start {
            currentWeekStart = startOfNewWeek
        }
    }

    // ✅ 날짜 포맷 함수들
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }

    func weekDateRangeString(from startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return "\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))"
    }

    func recordMessage(for status: Bool?) -> String {
        switch status {
        case true: return "복용 완료 ✅"
        case false: return "복용 실패 ❌"
        case nil: return "기록 없음 ⚪️"
        @unknown default: return "알 수 없음"
        }
    }
}

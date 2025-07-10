import SwiftUI

struct MonthlyStatsView: View {
    let calendar = Calendar.current
    let currentMonth: Date = Date()
    
    // 예시: 실제로는 DoseHistoryManager에서 불러옴
    let doseRecords: [DoseRecord] = DoseHistoryManager.shared.loadRecords()

    var body: some View {
        VStack(spacing: 20) {
            Text("월간 복약 통계")
                .font(.title2)
                .bold()

            // ✅ 1. 달력 표시
            CalendarGridView(records: doseRecords)

            // ✅ 2. 복약률 요약
            Text("이번 달 복용률: \(calculateMonthlyPercentage())%")
                .font(.headline)
                .padding(.top)

            Spacer()
        }
        .padding()
        .navigationTitle("월간 통계")
    }

    // ✅ 월간 복용률 계산
    func calculateMonthlyPercentage() -> Int {
        let thisMonth = calendar.dateInterval(of: .month, for: currentMonth)!
        let dailyGroups = Dictionary(grouping: doseRecords.filter {
            thisMonth.contains($0.takenTime)
        }) { record in
            calendar.startOfDay(for: record.takenTime)
        }

        let totalDays = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
        let successDays = dailyGroups.count

        return Int((Double(successDays) / Double(totalDays)) * 100)
    }
}


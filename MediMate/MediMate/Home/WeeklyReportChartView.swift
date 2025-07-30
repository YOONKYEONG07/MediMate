import SwiftUI
import Charts

struct MedicationStat: Identifiable {
    let id = UUID()
    let day: String
    let rate: Double
}

struct WeeklyReportChartView: View {
    let weekStart: Date
    let dailyRates: [Double]
    let weeklyAverage: Double

    var weeklyStats: [MedicationStat] {
        let calendar = Calendar.current
        let days = ["일", "월", "화", "수", "목", "금", "토"]

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let weekday = calendar.component(.weekday, from: date) - 1
            let rate = offset < dailyRates.count ? (dailyRates[offset].isNaN ? 0 : dailyRates[offset] * 100) : 0
            return MedicationStat(day: days[weekday], rate: rate)
        }
    }

    var averageRate: Double {
        let valid = dailyRates.filter { !$0.isNaN }
        return valid.isEmpty ? 0 : valid.reduce(0, +) / Double(valid.count) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 주간 복약률 비교")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(weeklyStats) { stat in
                    BarMark(
                        x: .value("요일", stat.day),
                        y: .value("복약률", stat.rate)
                    )
                    .foregroundStyle(Color.orange)
                    .annotation(position: .top) {
                        Text("\(Int(stat.rate))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                RuleMark(y: .value("주 평균", averageRate))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                    .foregroundStyle(.blue)
                    .annotation(position: .top, alignment: .center) {
                        Text("주 평균 \(Int(averageRate))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)
                            .offset(y: 4)
                    }
            }
            .chartYScale(domain: 0...120)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100])
            }
            .frame(height: 240)
            .padding(.horizontal)
        }
    }
}

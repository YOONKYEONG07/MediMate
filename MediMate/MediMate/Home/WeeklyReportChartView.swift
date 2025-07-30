import SwiftUI
import Charts

struct MedicationStat: Identifiable {
    let id = UUID()
    let day: String
    let rate: Double
}

struct WeeklyReportChartView: View {
    let records: [Date: Bool]
    let weekStart: Date
    let averageRates: [Double]
    let weeklyAverage: Double


    var weeklyStats: [MedicationStat] {
        let calendar = Calendar.current
        let days = ["일", "월", "화", "수", "목", "금", "토"]

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let dayStr = days[calendar.component(.weekday, from: date) - 1]
            let isTaken = records[calendar.startOfDay(for: date)] == true
            let takenRate = isTaken ? 100.0 : 0.0

            return MedicationStat(day: dayStr, rate: takenRate)
        }
    }

    var averageRate: Double {
        averageRates.reduce(0, +) / Double(averageRates.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 주간 복약률 비교")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                // ✅ 이번 주 복약률 막대
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

                // ✅ 주 평균선
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


import SwiftUI

struct WeeklyStatsView: View {
    // 예시 데이터. 실제로는 DoseHistoryManager 등에서 주간 기록 불러오기
    let stats: [WeeklyDoseStat] = [
        WeeklyDoseStat(weekday: "월", success: true),
        WeeklyDoseStat(weekday: "화", success: true),
        WeeklyDoseStat(weekday: "수", success: true),
        WeeklyDoseStat(weekday: "목", success: true),
        WeeklyDoseStat(weekday: "금", success: true),
        WeeklyDoseStat(weekday: "토", success: true),
        WeeklyDoseStat(weekday: "일", success: true)
    ]
    
    var allSuccess: Bool {
        stats.allSatisfy { $0.success }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("주간 복약 통계")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stats, id: \.weekday) { stat in
                        VStack {
                            Text(stat.weekday)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Image(systemName: stat.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(stat.success ? .green : .red)
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }

            if allSuccess {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("이번 주 목표 달성! 🎉")
                        .font(.subheadline)
                        .bold()
                }
                .padding(.top, 5)
            }

            NavigationLink(destination: MonthlyStatsView()) {
                Text("월간 통계 보기")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

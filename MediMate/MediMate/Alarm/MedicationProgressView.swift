import SwiftUI

struct MedicationProgressView: View {
    let percentage: Double

    var message: String {
        switch percentage {
        case 1.0:
            return "🎉 오늘도 성공!"
        case 0.75...:
            return "👍 거의 다 왔어요!"
        case 0.5...:
            return "💪 아직 반 남았어요!"
        case 0.25...:
            return "📌 시작이 반이에요!"
        default:
            return "💊 약 잊지 마세요!"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 100) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: percentage)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut, value: percentage)

                    Text("\(Int(percentage * 100))%")
                        .font(.title3)
                        .bold()
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 5) {
                    Text("복약률")
                        .font(.title)
                        .bold()
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            NavigationLink(destination: TodayMedicationListView()) {
                Text("오늘 복용 약 보기")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(minHeight: 130)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    MedicationProgressView(percentage: 0.75)
}

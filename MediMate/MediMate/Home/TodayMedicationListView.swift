import SwiftUI

struct TodayMedicationListView: View {
    let todayReminders: [MedicationReminder]  // ✅ 파라미터 추가

    var body: some View {
        List(todayReminders, id: \.id) { reminder in
            VStack(alignment: .leading) {
                Text(reminder.name)
                    .font(.headline)
                Text(String(format: "복용 시간: %02d:%02d", reminder.hour, reminder.minute))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("오늘 복용 약")
    }
}

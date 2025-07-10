import SwiftUI

struct HomeView: View {
    @State private var reminders: [MedicationReminder] = []
    @State private var takenReminderIDs: Set<String> = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // ✅ 1. 복용률 원형 그래프
                    MedicationProgressView(percentage: calculateProgress())
                    
                    // ✅ 2. 다가오는 복용 약
                    UpcomingMedicationView(reminders: reminders, takenReminderIDs: $takenReminderIDs)
                    
                    // ✅ 3. 주간 복약 통계
                    WeeklyStatsView()
                    
                    // ✅ 4. 건강 팁
                    HealthTipView()
                    
                    Divider()
                }
                .padding()
            }
            .navigationTitle("내 손 안의 AI 약사")
            .onAppear {
                reminders = NotificationManager.instance.loadReminders()
            }
        }
    }

    // 복용률 계산
    private func calculateProgress() -> Double {
        guard !reminders.isEmpty else { return 0 }
        let taken = reminders.filter { takenReminderIDs.contains($0.id) }.count
        return Double(taken) / Double(reminders.count)
    }
}


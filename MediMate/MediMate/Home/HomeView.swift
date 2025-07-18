import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var chatInputManager: ChatInputManager

    @State private var reminders: [MedicationReminder] = []
    @State private var takenReminderIDs: Set<String> = []  // 복용 완료된 알림 ID 목록
    @State private var skippedReminderIDs: Set<String> = []  // 복용 안함 처리된 알림 ID 목록
    @State private var dailyQuestion: HealthQuestion = getDailyQuestion()

    @State private var refreshID = UUID()  // 리렌더링을 위한 상태
    
    // 복약률을 UserDefaults에 저장하여 다른 페이지에서 갔다 올 때 값 유지
    @AppStorage("progress") private var progress: Double = 0.0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    NavigationLink(destination: ReportView()) {
                        Text("리포트 보기")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }

                    // 복용률 원형 그래프
                    MedicationProgressView(percentage: progress)

                    UpcomingMedicationView(
                        reminders: reminders,
                        takenReminderIDs: $takenReminderIDs,
                        skippedReminderIDs: $skippedReminderIDs,
                        refreshID: $refreshID
                    )

                    HealthTipView()

                    HealthQuestionCard(question: dailyQuestion) {
                        chatInputManager.prefilledMessage = dailyQuestion.question
                        selectedTab = 3
                    }
                    .padding(.horizontal)

                    Divider()
                }
                .padding()
            }
            .navigationTitle("내 손 안의 AI 약사")
            .onAppear {
                reminders = NotificationManager.instance.loadReminders()

                // 초기화: 복약률 계산을 위해 복용 완료 및 복용 안함 상태 리셋
                takenReminderIDs.removeAll()
                skippedReminderIDs.removeAll()

                // 복약률을 새로 0%로 초기화하고 계산
                progress = 0.0
                updateProgress()
            }
            .onChange(of: refreshID) { _ in
                updateProgress()
            }
        }
    }

    // 복약률 계산 (알림 개수에 맞춰)
    private func updateProgress() {
        // 전체 알림 개수 (복용 완료 + 복용 안함)
        let totalReminders = reminders.count
        // 복용 완료된 알림 개수만 반영
        let takenCount = takenReminderIDs.count
        let skippedCount = skippedReminderIDs.count

        // 복약률 계산 (복용 완료된 알림 개수 / 전체 알림 개수)
        guard totalReminders > 0 else {
            progress = 0.0  // 알림이 없으면 복약률 0%
            return
        }

        // 복약률 계산: 복용 완료된 알림 개수 / 전체 알림 개수
        progress = Double(takenCount) / Double(totalReminders)

        // 복약률이 100%를 넘지 않도록 설정
        progress = min(progress, 1.0)

        // 복약률 계산 결과를 UserDefaults에 저장
        print("총 알림 수: \(reminders.count), 복용 완료: \(takenReminderIDs.count), 복용 안함: \(skippedReminderIDs.count), 복약률: \(progress)")
    }
}







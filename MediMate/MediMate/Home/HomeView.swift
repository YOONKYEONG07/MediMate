import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var chatInputManager: ChatInputManager

    @State private var reminders: [MedicationReminder] = []
    @State private var takenReminderIDs: Set<String> = []
    @State private var skippedReminderIDs: Set<String> = []
    @State private var dailyQuestion: HealthQuestion = getDailyQuestion()

    @State private var refreshID = UUID()
    @AppStorage("progress") private var progress: Double = 0.0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {

                    // ✅ 타이틀 + 오늘 날짜
                    VStack(alignment: .leading, spacing: 4) {
                        Text("내 손 안의 AI 약사")
                            .font(.largeTitle)
                            .bold()

                        Text("📅 \(formattedToday())")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // ✅ 리포트 보기 버튼
                    NavigationLink(destination: ReportView()) {
                        Text("리포트 보기")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // ✅ 복용률 원형 그래프
                    MedicationProgressView(percentage: progress)
                        .padding(.horizontal)

                    // ✅ 다가오는 복용
                    UpcomingMedicationView(
                        reminders: reminders,
                        takenReminderIDs: $takenReminderIDs,
                        skippedReminderIDs: $skippedReminderIDs,
                        refreshID: $refreshID
                    )
                    .padding(.horizontal)

                    // ✅ 건강 팁
                    HealthTipView()

                    // ✅ 오늘의 건강 궁금증
                    HealthQuestionCard(question: dailyQuestion) {
                        chatInputManager.prefilledMessage = dailyQuestion.question
                        selectedTab = 3
                    }

                    Divider()
                        .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .onAppear {
                reminders = NotificationManager.instance.loadReminders()
                takenReminderIDs.removeAll()
                skippedReminderIDs.removeAll()
                progress = 0.0
                updateProgress()
            }
            .onChange(of: refreshID) { _ in
                updateProgress()
            }
        }
    }

    // ✅ 날짜 포맷 함수
    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: Date())
    }

    // ✅ 복약률 계산
    private func updateProgress() {
        let totalReminders = reminders.count
        let takenCount = takenReminderIDs.count

        guard totalReminders > 0 else {
            progress = 0.0
            return
        }

        progress = Double(takenCount) / Double(totalReminders)
        progress = min(progress, 1.0)

        print("총 알림 수: \(reminders.count), 복용 완료: \(takenReminderIDs.count), 복용 안함: \(skippedReminderIDs.count), 복약률: \(progress)")
    }
}

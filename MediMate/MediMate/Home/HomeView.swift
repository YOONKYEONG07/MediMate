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

                    // ✅ 복약률 원형 그래프
                    MedicationProgressView(
                        percentage: progress,
                        reminders: reminders  // ✅ 추가됨
                    )
                        .padding(.horizontal)

                    // ✅ 다가오는 복용
                    UpcomingDoseView(
                        reminders: reminders,
                        takenReminderIDs: $takenReminderIDs,
                        skippedReminderIDs: $skippedReminderIDs,
                        refreshID: $refreshID,
                        onDoseUpdated: updateProgress
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

                // ✅ UserDefaults에서 복용/미복용한 알림 ID 복원
                takenReminderIDs = loadIDs(forKey: todayTakenKey)
                skippedReminderIDs = loadIDs(forKey: todaySkippedKey)

                updateProgress()
            }
            .onChange(of: refreshID) { _ in
                updateProgress()
            }
        }
    }

    // ✅ 날짜 포맷
    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: Date())
    }

    // ✅ 복약률 계산
    private func updateProgress() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // ✅ 오늘만 필터링
        let todayReminders = reminders.filter { reminder in
            let reminderDate = calendar.date(bySettingHour: reminder.hour, minute: reminder.minute, second: 0, of: today)!
            return calendar.isDate(reminderDate, inSameDayAs: today)
        }

        // ✅ 중복 제거: 하나의 알림 ID당 한 번만 복용
        let todayTaken = todayReminders.filter { reminder in
            takenReminderIDs.contains(reminder.id)
        }

        let total = todayReminders.count
        let taken = todayTaken.count

        guard total > 0 else {
            progress = 0.0
            return
        }

        progress = Double(taken) / Double(total)
        progress = min(progress, 1.0)  // ✅ 최대 100% 넘지 않도록 제한

        print("📊 총: \(total), 복용 완료: \(taken), 복약률: \(progress)")
    }

    // ✅ UserDefaults 키
    private var todayTakenKey: String {
        "taken-\(todayString())"
    }

    private var todaySkippedKey: String {
        "skipped-\(todayString())"
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // ✅ 저장된 ID 복원
    private func loadIDs(forKey key: String) -> Set<String> {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            return Set(saved)
        }
        return []
    }

    // ✅ 저장 함수 (복용 완료/안함 버튼 눌렀을 때 View에서 호출)
    func saveIDs(_ set: Set<String>, forKey key: String) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }
}

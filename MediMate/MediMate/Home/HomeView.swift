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
    let onTap: () -> Void = {}

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {

                    // ✅ 타이틀 + 오늘 날짜
                    VStack(alignment: .leading, spacing: 12) {
                        Text("내 손 안의 AI 약사")
                            .font(.largeTitle)
                            .bold()

                        Text("\(formattedToday())")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // ✅ 맞춤 영양제 추천 카드
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {

                            Text("🌟맞춤 영양제 추천")
                                .font(.headline)
                            
                            Text("건강 상태에 따라\n나에게 딱 맞는 영양제를\n추천 받아보세요.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // ✅ 버튼만 누르면 이동되게 수정
                            NavigationLink(destination: SupplementRecommendationView(selectedTab: $selectedTab)) {
                                Text("AI 약사에게 물어보기 →")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                
                            }
                            .padding(.top, 4)
                        }

                        Spacer()

                        // 💊 오른쪽 알약 이미지
                        Image("supplementPills3D")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    .padding(.horizontal)


                    
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
                        reminders: reminders,
                        refreshID: $refreshID
                    )
                    .padding(.horizontal)

                    // ✅ 다가오는 복용 (중복 약 제거된 상태로 전달)
                    UpcomingDoseView(
                        reminders: mergeSameDrugReminders(reminders: reminders),
                        takenIDs: $takenReminderIDs,        // ✅ 변경
                        skippedIDs: $skippedReminderIDs,    // ✅ 변경
                        refreshID: $refreshID,
                        onDoseUpdated: updateProgress
                    )
                    .padding(.horizontal)

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

        let todayReminders = Array(reminders).filter { (reminder: MedicationReminder) in
            let reminderDate = calendar.date(
                bySettingHour: reminder.hours.first ?? 0,
                minute: reminder.minutes.first ?? 0,
                second: 0,
                of: today
            )!
            return calendar.isDate(reminderDate, inSameDayAs: today)
        }

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
        progress = min(progress, 1.0)

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

    // ✅ 저장 함수
    func saveIDs(_ set: Set<String>, forKey key: String) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    // ✅ 약 이름 기준으로 그룹화 + 시간 병합
    private func mergeSameDrugReminders(reminders: [MedicationReminder]) -> [MedicationReminder] {
        var grouped: [String: [MedicationReminder]] = [:]

        for reminder in reminders {
            grouped[reminder.name, default: []].append(reminder)
        }

        return grouped.map { name, group in
            let times = zip(group.flatMap { $0.hours }, group.flatMap { $0.minutes })
                .map { String(format: "%02d:%02d", $0, $1) }
                .sorted()
                .joined(separator: ", ")

            var merged = group[0]
            merged.timeDescription = times // 이 필드가 MedicationReminder에 있어야 함
            return merged
        }
    }
}

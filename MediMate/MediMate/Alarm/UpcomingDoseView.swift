import SwiftUI
import UserNotifications

struct UpcomingDoseView: View {
    let reminders: [MedicationReminder]
    @Binding var takenReminderIDs: Set<String>
    @Binding var skippedReminderIDs: Set<String>
    @Binding var refreshID: UUID
    var onDoseUpdated: () -> Void

    var upcomingReminder: MedicationReminder? {
        let now = Date()
        let calendar = Calendar.current

        return reminders
            .filter { !takenReminderIDs.contains($0.id) && !skippedReminderIDs.contains($0.id) }
            .sorted {
                let date1 = calendar.date(bySettingHour: $0.hours.first ?? 0, minute: $0.minutes.first ?? 0, second: 0, of: now)!
                let date2 = calendar.date(bySettingHour: $1.hours.first ?? 0, minute: $1.minutes.first ?? 0, second: 0, of: now)!
                return date1 < date2
            }
            .first
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("다가오는 복용")
                .font(.title2)
                .bold()

            if let reminder = upcomingReminder {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(reminder.name)
                                .font(.headline)
                            Text(String(format: "복용 시간: %02d:%02d", reminder.hours.first ?? 0, reminder.minutes.first ?? 0))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        // ✅ 복용 완료 버튼
                        Button(action: {
                            takenReminderIDs.insert(reminder.id)

                            let key = "taken-\(todayString())"
                            UserDefaults.standard.set(Array(takenReminderIDs), forKey: key)

                            onDoseUpdated()

                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: true
                            )
                            DoseHistoryManager.shared.saveRecord(record)

                            // 기존 리마인드 알림 제거
                            let reminderID = "reminder_\(reminder.id)_remind"
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID])
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("복용 완료")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .font(.subheadline.bold())
                            .cornerRadius(14)
                        }

                        // ✅ 복용 안함 버튼 + 2분 뒤 알림 + 화면에 다시 표시
                        Button(action: {
                            skippedReminderIDs.insert(reminder.id)

                            let key = "skipped-\(todayString())"
                            UserDefaults.standard.set(Array(skippedReminderIDs), forKey: key)

                            refreshID = UUID()

                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: false
                            )
                            DoseHistoryManager.shared.saveRecord(record)

                            // 🔔 2분 후 리마인드 알림 등록
                            let content = UNMutableNotificationContent()
                            content.title = "\(reminder.name) 복약 리마인드"
                            content.body = "💊 복용 안하셨나요? 잊지 말고 드세요!"
                            content.sound = .default

                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)
                            let requestID = "reminder_\(reminder.id)_remind"
                            let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestID])
                            UNUserNotificationCenter.current().add(request) { error in
                                if let error = error {
                                    print("❌ 리마인드 알림 등록 실패: \(error.localizedDescription)")
                                } else {
                                    print("✅ 30분 뒤 리마인드 알림 등록 완료")
                                }
                            }

                            // ⏱ 2분 후 UI에 다시 복약 카드 표시
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1800) {
                                skippedReminderIDs.remove(reminder.id)
                                let updated = skippedReminderIDs
                                UserDefaults.standard.set(Array(updated), forKey: key)
                                refreshID = UUID()
                            }
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("복용 안함")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .font(.subheadline.bold())
                            .cornerRadius(14)
                        }
                    }

                    Text("※ 복용 안함을 누르면 2분 뒤 다시 알림을 드려요! (테스트용)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            } else {
                Text("예정된 복용이 없습니다 🎉")
                    .foregroundColor(.gray)
                    .padding(.vertical)
            }
        }
        .padding(.top)
    }
}


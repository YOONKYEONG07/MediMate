import SwiftUI
import UserNotifications

struct DoseInstance: Identifiable {
    let id: String
    let reminder: MedicationReminder
    let hour: Int
    let minute: Int
    var date: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

struct UpcomingDoseView: View {
    let reminders: [MedicationReminder]
    @Binding var takenIDs: Set<String>
    @Binding var skippedIDs: Set<String>
    @Binding var refreshID: UUID
    var onDoseUpdated: () -> Void

    // ✅ 오늘 복약 인스턴스 중 다음 복용 1개만
    var upcomingDoseInstance: DoseInstance? {
        let calendar = Calendar.current
        let now = Date()
        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        let today = weekdaySymbols[calendar.component(.weekday, from: now) - 1]

        let allInstances: [DoseInstance] = reminders.flatMap { reminder in
            guard reminder.days.contains(today) else { return [] as [DoseInstance] }
            return zip(reminder.hours, reminder.minutes).map { hour, minute in
                DoseInstance(
                    id: "\(reminder.id)_\(hour)_\(minute)",
                    reminder: reminder,
                    hour: hour,
                    minute: minute
                )
            }
        }



        return allInstances
            .filter { !takenIDs.contains($0.id) && !skippedIDs.contains($0.id) }
            .sorted { $0.date < $1.date }
            .first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("다가오는 복용")
                .font(.title2)
                .bold()

            if let dose = upcomingDoseInstance {
                let reminder = dose.reminder

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(reminder.name)
                                .font(.headline)
                            Text(String(format: "복용 시간: %02d:%02d", dose.hour, dose.minute))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        // ✅ 복용 완료
                        Button(action: {
                            takenIDs.insert(dose.id)
                            UserDefaults.standard.set(Array(takenIDs), forKey: "taken-\(todayString())")
                            refreshID = UUID()
                            onDoseUpdated()

                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: dose.date,
                                taken: true
                            )
                            DoseHistoryManager.shared.saveRecord(record)

                            // 리마인드 제거
                            let requestID = "reminder_\(dose.id)_remind"
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestID])
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

                        // ✅ 복용 안함 + 리마인드
                        Button(action: {
                            skippedIDs.insert(dose.id)
                            UserDefaults.standard.set(Array(skippedIDs), forKey: "skipped-\(todayString())")
                            refreshID = UUID()

                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: dose.date,
                                taken: false
                            )
                            DoseHistoryManager.shared.saveRecord(record)

                            // 리마인드 알림
                            let content = UNMutableNotificationContent()
                            content.title = "💊 복약 리마인드"
                            content.body = "\(reminder.name)을 아직 복용하지 않으셨어요! 잊지 말고 드세요."
                            content.sound = .default

                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)
                            let requestID = "reminder_\(dose.id)_remind"
                            let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestID])
                            UNUserNotificationCenter.current().add(request)

                            // 30분 후 UI 복원
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1800) {
                                skippedIDs.remove(dose.id)
                                UserDefaults.standard.set(Array(skippedIDs), forKey: "skipped-\(todayString())")
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

                    Text("※ 복용 안함을 누르면 30분 뒤 다시 알림을 드려요!")
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

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}


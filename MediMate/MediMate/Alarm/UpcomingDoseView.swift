import SwiftUI

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
                let date1 = calendar.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: now)!
                let date2 = calendar.date(bySettingHour: $1.hour, minute: $1.minute, second: 0, of: now)!
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
                            Text(String(format: "복용 시간: %02d:%02d", reminder.hour, reminder.minute))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
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

                        Button(action: {
                            skippedReminderIDs.insert(reminder.id)

                            let key = "skipped-\(todayString())"
                            UserDefaults.standard.set(Array(skippedReminderIDs), forKey: key)
                            
                            refreshID = UUID() // ✅ 강제 리렌더링 트리거

                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: false
                            )
                            DoseHistoryManager.shared.saveRecord(record)
                            // 🔁 30분 뒤에 다시 등장할 수 있도록 refreshID 재갱신
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1800) {
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
}


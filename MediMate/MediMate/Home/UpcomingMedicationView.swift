import SwiftUI

struct UpcomingMedicationView: View {
    let reminders: [MedicationReminder]
    @Binding var takenReminderIDs: Set<String>
    @Binding var skippedReminderIDs: Set<String>
    @Binding var refreshID: UUID

    var upcomingReminder: MedicationReminder? {
        let now = Date()
        let calendar = Calendar.current

        return reminders
            .filter { !takenReminderIDs.contains($0.id) && !skippedReminderIDs.contains($0.id) }
            .sorted {
                let hour1 = $0.hours.first ?? 0
                let minute1 = $0.minutes.first ?? 0
                let hour2 = $1.hours.first ?? 0
                let minute2 = $1.minutes.first ?? 0

                let date1 = calendar.date(bySettingHour: hour1, minute: minute1, second: 0, of: now)!
                let date2 = calendar.date(bySettingHour: hour2, minute: minute2, second: 0, of: now)!
                return date1 < date2
            }
            .first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("다가오는 복용")
                .font(.title2)
                .bold()

            if let reminder = upcomingReminder {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(reminder.name)
                                .font(.headline)
                            Text(String(format: "복용 시간: %02d:%02d",
                                        reminder.hours.first ?? 0,
                                        reminder.minutes.first ?? 0))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        // 💊 복용 완료
                        Button(action: {
                            takenReminderIDs.insert(reminder.id)
                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: true
                            )
                            DoseHistoryManager.shared.saveRecord(record)

                            DoseRecordManager.shared.saveDoseRecord(
                                userID: "testUser123",
                                date: Date(),
                                medName: reminder.name,
                                taken: true
                            )

                            refreshID = UUID()
                        }) {
                            Label("복용 완료", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        // ⏰ 복용 안함
                        Button(action: {
                            skippedReminderIDs.insert(reminder.id)
                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: false
                            )
                            DoseHistoryManager.shared.saveRecord(record)

                            DoseRecordManager.shared.saveDoseRecord(
                                userID: "testUser123",
                                date: Date(),
                                medName: reminder.name,
                                taken: false
                            )

                        }) {
                            Label("복용 안함", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
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


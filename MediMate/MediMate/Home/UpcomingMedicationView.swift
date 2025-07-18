import SwiftUI

struct UpcomingMedicationView: View {
    let reminders: [MedicationReminder]
    @Binding var takenReminderIDs: Set<String>
    @Binding var skippedReminderIDs: Set<String> // 복용 안함 처리된 알림 ID 목록
    @Binding var refreshID: UUID

    var upcomingReminder: MedicationReminder? {
        let now = Date()
        let calendar = Calendar.current

        return reminders
            .filter { !takenReminderIDs.contains($0.id) && !skippedReminderIDs.contains($0.id) } // 복용 완료 또는 복용 안함 상태인 알림 제외
            .sorted {
                let date1 = calendar.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: now)!
                let date2 = calendar.date(bySettingHour: $1.hour, minute: $1.minute, second: 0, of: now)!
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
                            Text(String(format: "복용 시간: %02d:%02d", reminder.hour, reminder.minute))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        // 💊 복용 완료 버튼
                        Button(action: {
                            takenReminderIDs.insert(reminder.id)
                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: true
                            )
                            DoseHistoryManager.shared.saveRecord(record)

                            // ✅ 복약률 갱신을 위해 refreshID 변경 (리렌더링 트리거)
                            refreshID = UUID()  // 복용 완료 시에만 리렌더링
                        }) {
                            Label("복용 완료", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        // ⏰ 복용 안함 버튼
                        Button(action: {
                            skippedReminderIDs.insert(reminder.id)  // 복용 안함 상태 저장
                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: false
                            )
                            DoseHistoryManager.shared.saveRecord(record)

                            // ✅ 복용 안함 버튼에서 복약률 갱신하지 않음
                            // refreshID를 갱신하지 않음
                        }) {
                            Label("복용 안함", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }

                    // ℹ️ 안내 문구
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



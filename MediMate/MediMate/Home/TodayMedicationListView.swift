import SwiftUI

struct TodayMedicationListView: View {
    let reminders: [MedicationReminder]
    @Binding var refreshID: UUID  // ✅ 홈 뷰와 동기화용
    @State private var records: [DoseRecord] = []

    var body: some View {
        List {
            ForEach(todayReminders(), id: \.id) { reminder in
                let record = findRecord(for: reminder.name)

                Button {
                    toggleRecord(for: reminder.name)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reminder.name)
                            .font(.headline)

                        Text("⏰ 복용 예정 시간: \(formattedTime(hour: reminder.hour, minute: reminder.minute))")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if let record = record {
                            if record.taken {
                                Text("✅ 복용 완료 시간: \(formattedDate(record.takenTime)) (누르면 취소 가능)")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            } else {
                                Text("❌ 복용 안함 (누르면 복용으로 변경)")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        } else {
                            Text("⚪ 복용 기록 없음")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("오늘 복용 약")
        .onAppear {
            loadTodayRecords()
        }
    }

    private func todayReminders() -> [MedicationReminder] {
        let today = Calendar.current.startOfDay(for: Date())
        return reminders.filter { reminder in
            let scheduledTime = Calendar.current.date(
                bySettingHour: reminder.hour,
                minute: reminder.minute,
                second: 0,
                of: today
            )!
            return Calendar.current.isDate(scheduledTime, inSameDayAs: today)
        }
    }

    private func loadTodayRecords() {
        DoseHistoryManager.shared.fetchTodayDoseRecords(userID: "testUser123") { fetched in
            self.records = fetched
        }
    }

    private func findRecord(for name: String) -> DoseRecord? {
        return records.first { $0.medicineName == name }
    }
    
    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func toggleRecord(for name: String) {
        guard var record = findRecord(for: name),
              let reminder = reminders.first(where: { $0.name == name }) else { return }

        record.taken.toggle()
        record.takenTime = Date()

        // ✅ ID 기준 저장
        let key = "taken-\(todayString())"
        var ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])

        if record.taken {
            ids.insert(reminder.id)
        } else {
            ids.remove(reminder.id)
        }
        UserDefaults.standard.set(Array(ids), forKey: key)

        // ✅ Firestore 업데이트
        DoseHistoryManager.shared.updateDoseRecord(record) {
            loadTodayRecords()
            DispatchQueue.main.async {
                refreshID = UUID()
            }
        }
    }

    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formattedTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }
}

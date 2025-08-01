import SwiftUI
import FirebaseAuth

struct TodayDoseInstance: Identifiable {
    let id: String
    let reminder: MedicationReminder
    let hour: Int
    let minute: Int

    var date: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps)!
    }
}

struct TodayMedicationListView: View {
    let reminders: [MedicationReminder]
    @Binding var refreshID: UUID
    @State private var records: [DoseRecord] = []

    var body: some View {
        List {
            ForEach(todayDoseInstances()) { dose in
                let record = findRecord(for: dose)

                Button {
                    toggleRecord(for: dose, existing: record)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dose.reminder.name)
                            .font(.headline)

                        Text("⏰ 복용 예정 시간: \(formattedTime(hour: dose.hour, minute: dose.minute))")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if let record = record, record.taken {
                            Text("✅ 복용 완료 시간: \(formattedDate(record.takenTime)) (누르면 취소 가능)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else {
                            Text("❌ 복용 안함 (누르면 복용으로 변경)")
                                .font(.subheadline)
                                .foregroundColor(.red)
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

    private func todayDoseInstances() -> [TodayDoseInstance] {
        let now = Date()
        let weekday = Calendar.current.component(.weekday, from: now)
        let weekdaySymbol = ["일", "월", "화", "수", "목", "금", "토"][weekday - 1]

        var result: [TodayDoseInstance] = []

        for reminder in reminders {
            if reminder.days.contains(weekdaySymbol) {
                for (hour, minute) in zip(reminder.hours, reminder.minutes) {
                    result.append(TodayDoseInstance(
                        id: "\(reminder.id)_\(hour)_\(minute)",
                        reminder: reminder,
                        hour: hour,
                        minute: minute
                    ))
                }
            }
        }

        return result.sorted { $0.date < $1.date }
    }

    private func loadTodayRecords() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        DoseHistoryManager.shared.fetchTodayDoseRecords(userID: uid) { fetched in
            self.records = fetched
        }
    }

    private func findRecord(for dose: TodayDoseInstance) -> DoseRecord? {
        return records.first {
            $0.medicineName == dose.reminder.name &&
            Calendar.current.component(.hour, from: $0.takenTime) == dose.hour &&
            Calendar.current.component(.minute, from: $0.takenTime) == dose.minute
        }
    }

    private func toggleRecord(for dose: TodayDoseInstance, existing: DoseRecord?) {
        let doseID = dose.id
        let key = "taken-\(todayString())"
        var ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])

        if var record = existing {
            record.taken.toggle()
            record.takenTime = Date()

            if let index = records.firstIndex(where: { $0.id == record.id }) {
                records[index] = record
            }

            if record.taken == false && ids.contains(doseID) {
                ids.remove(doseID)
            } else {
                ids.insert(doseID)
            }

            UserDefaults.standard.set(Array(ids), forKey: key)

            DoseHistoryManager.shared.updateDoseRecord(record) {
                loadTodayRecords()
                refreshID = UUID()
            }
        } else {
            let newRecord = DoseRecord(
                id: UUID().uuidString,
                medicineName: dose.reminder.name,
                takenTime: dose.date,
                taken: true
            )
            records.append(newRecord)

            ids.insert(doseID)
            UserDefaults.standard.set(Array(ids), forKey: key)

            DoseHistoryManager.shared.saveRecord(newRecord)
            refreshID = UUID()
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formattedTime(hour: Int, minute: Int) -> String {
        return String(format: "%02d:%02d", hour, minute)
    }
}


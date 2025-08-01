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

    @State private var reorderedDoses: [DoseInstance] = []
    @State private var currentIndex = 0
    @State private var skippedUntil: [String: Date] = [:]
    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("다가오는 복용")
                .font(.title2).bold()

            if reorderedDoses.isEmpty {
                Text("예정된 복용이 없습니다 🎉")
                    .foregroundColor(.gray)
                    .padding(.vertical)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(reorderedDoses.indices, id: \.self) { index in
                        let dose = reorderedDoses[index]
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
                            }

                            HStack(spacing: 12) {
                                Button(action: {
                                    takenIDs.insert(dose.id)
                                    UserDefaults.standard.set(Array(takenIDs), forKey: "taken-\(todayString())")

                                    let record = DoseRecord(
                                        id: UUID().uuidString,
                                        medicineName: reminder.name,
                                        takenTime: dose.date,
                                        taken: true
                                    )
                                    DoseHistoryManager.shared.saveRecord(record)

                                    // 알림 취소
                                    let calendar = Calendar.current
                                    let weekday = calendar.component(.weekday, from: Date())
                                    let alarmID = "reminder_\(reminder.id)_\(dose.hour)_\(dose.minute)_\(weekday)"
                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmID])

                                    reorderedDoses.remove(at: index)
                                    currentIndex = min(currentIndex, reorderedDoses.count - 1)

                                    refreshID = UUID()
                                    onDoseUpdated()
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
                                    let doseID = dose.id
                                    let name = reminder.name.isEmpty ? "이름 없는 약" : reminder.name

                                    let record = DoseRecord(
                                        id: UUID().uuidString,
                                        medicineName: reminder.name,
                                        takenTime: dose.date,
                                        taken: false
                                    )
                                    DoseHistoryManager.shared.saveRecord(record)

                                    skippedUntil[doseID] = Date().addingTimeInterval(28 * 60)

                                    NotificationManager.instance.scheduleReminderAfterSkip(
                                        title: "💊 복약 리마인드",
                                        body: "\(name)을 아직 복용하지 않으셨어요! 잊지 말고 드세요!",
                                        reminderID: doseID
                                    )

                                    updateDoses()
                                    currentIndex = 0
                                    refreshID = UUID()
                                    onDoseUpdated()
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

                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                        .tag(index)
                    }
                }
                .frame(height: 140)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentIndex)
                .padding(.bottom, 20)

                Text("⏰ \"복용 안함\"을 누르면 30분 뒤에 리마인드 알림을 드려요!")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 12)
            }
        }
        .padding(.top)
        .onAppear {
            updateDoses()
        }
        .onChange(of: reminders.map(\.id)) { _ in
            updateDoses()
        }
        .onReceive(timer) { input in
            let calendar = Calendar.current
            if !calendar.isDate(input, inSameDayAs: now) {
                now = input
            }
            updateDoses()
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func updateDoses() {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let weekdaySymbol = ["일", "월", "화", "수", "목", "금", "토"][weekday - 1]

        var allDoses: [DoseInstance] = []

        for reminder in reminders {
            if reminder.days.contains(weekdaySymbol) {
                for (hour, minute) in zip(reminder.hours, reminder.minutes) {
                    let dose = DoseInstance(
                        id: "\(reminder.id)_\(hour)_\(minute)",
                        reminder: reminder,
                        hour: hour,
                        minute: minute
                    )
                    allDoses.append(dose)
                }
            }
        }

        let filtered = allDoses.filter {
            !takenIDs.contains($0.id) &&
            (skippedUntil[$0.id] ?? .distantPast) < now
        }

        reorderedDoses = filtered.sorted { $0.date < $1.date }
    }
}


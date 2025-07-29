import SwiftUI

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

    var upcomingDoses: [DoseInstance] {
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

        let filtered = allDoses.filter { !takenIDs.contains($0.id) }
        let sorted = filtered.sorted { $0.date < $1.date }

        return sorted
    }

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
                                    let record = DoseRecord(
                                        id: UUID().uuidString,
                                        medicineName: reminder.name,
                                        takenTime: dose.date,
                                        taken: false
                                    )
                                    DoseHistoryManager.shared.saveRecord(record)

                                    let skipped = reorderedDoses.remove(at: index)
                                    reorderedDoses.append(skipped)

                                    currentIndex = min(currentIndex, reorderedDoses.count - 1)

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
                .frame(height: 140) // 카드 크기 고정 (적당히 꽉 차게 보이게)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentIndex)
                .padding(.bottom, 20)

            }
        }
        .padding(.top)
        .onAppear {
            reorderedDoses = upcomingDoses
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

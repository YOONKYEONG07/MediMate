import SwiftUI

struct UpcomingDoseView: View {
    let reminders: [MedicationReminder]
    @Binding var takenReminderIDs: Set<String>

    var upcomingReminder: MedicationReminder? {
        let now = Date()
        let calendar = Calendar.current

        return reminders
            .filter { !takenReminderIDs.contains($0.id) }
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
                        Button("복용 완료") {
                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: true
                            )
                            DoseHistoryManager.shared.saveRecord(record)
                            takenReminderIDs.insert(reminder.id)
                        }

                        Button("복용 안함") {
                            let record = DoseRecord(
                                id: UUID().uuidString,
                                medicineName: reminder.name,
                                takenTime: Date(),
                                taken: false
                            )
                            DoseHistoryManager.shared.saveRecord(record)
                            takenReminderIDs.insert(reminder.id)
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
}//
//  UpcomingMedicationView.swift
//  MediMate
//
//  Created by 지연이의 MAC on 7/17/25.
//


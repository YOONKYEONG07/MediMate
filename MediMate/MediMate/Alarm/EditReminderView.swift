import SwiftUI

struct EditReminderView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var reminder: MedicationReminder
    @State private var selectedTime: Date

    init(reminder: MedicationReminder) {
        _reminder = State(initialValue: reminder)

        // ✅ 배열에서 첫 시간을 가져와 초기화
        let hour = reminder.hours.first ?? 8
        let minute = reminder.minutes.first ?? 0
        let calendar = Calendar.current
        let components = DateComponents(hour: hour, minute: minute)
        _selectedTime = State(initialValue: calendar.date(from: components) ?? Date())
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("복용 시간 수정")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 10) {
                Text("약 이름")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(reminder.name)
                    .font(.headline)

                Text("복용 시간")
                    .font(.caption)
                    .foregroundColor(.gray)
                DatePicker("시간 선택", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
            }

            Spacer()

            Button(action: {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: selectedTime)
                let minute = calendar.component(.minute, from: selectedTime)

                // ✅ 시간 업데이트 (단일 시간 기준)
                reminder.hours = [hour]
                reminder.minutes = [minute]

                // 확인용 출력
                print("🛠️ 수정된 시간: \(hour):\(minute) for \(reminder.name)")

                // 저장 기능 연결 가능: 예) NotificationManager.instance.updateReminder(reminder)

                presentationMode.wrappedValue.dismiss()
            }) {
                Text("저장하기")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .navigationTitle("알림 수정")
    }
}


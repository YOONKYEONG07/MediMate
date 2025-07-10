import SwiftUI

struct EditReminderView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var reminder: MedicationReminder
    @State private var selectedTime: Date

    init(reminder: MedicationReminder) {
        _reminder = State(initialValue: reminder)
        // 현재 시간 설정
        let calendar = Calendar.current
        let components = DateComponents(hour: reminder.hour, minute: reminder.minute)
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

                // 임시 출력: 실제 저장 대신 콘솔에 확인
                print("🛠️ 수정된 시간: \(hour):\(minute) for \(reminder.name)")
                
                // 일단 화면만 닫기
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


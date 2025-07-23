import SwiftUI

struct ReminderAddView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var medicineName: String = ""
    @State private var reminderTime: Date = Date()
    @State private var selectedDays: Set<String> = []
    
    let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("약 정보")) {
                    TextField("약 이름을 입력하세요", text: $medicineName)
                }

                Section(header: Text("복용 시간")) {
                    DatePicker("시간 선택", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }

                Section(header: Text("복용 요일")) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Toggle(isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        )) {
                            Text(day)
                        }
                    }
                }

                Section {
                    Button("저장") {
                        saveReminder()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("알림 추가")
        }
    }

    func saveReminder() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        let reminder = MedicationReminder(
            id: UUID().uuidString,
            name: medicineName,
            hour: hour,
            minute: minute,
            days: Array(selectedDays)
        )
        
        // 예: 로컬 또는 Firestore 저장
        NotificationManager.instance.saveReminder(reminder)
        NotificationManager.instance.scheduleNotification(
            title: "\(medicineName) 복용 알림",
            body: "\(hour):\(minute) 복용 시간입니다!",
            hour: hour,
            minute: minute
        )
    }
}

import SwiftUI

struct ReminderEditView: View {
    @Binding var reminder: MedicationReminder
    @Environment(\.presentationMode) var presentationMode

    var onDelete: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil  // ✅ 저장 후 부모 뷰 갱신용 콜백

    @State private var editedName: String = ""
    @State private var reminderTime: Date = Date()
    @State private var selectedDays: Set<String> = []

    let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        NavigationView {
            Form {
                // 약 정보
                Section(header: Text("약 정보")) {
                    TextField("약 이름을 입력하세요", text: $editedName)
                }

                // 복용 시간
                Section(header: Text("복용 시간")) {
                    DatePicker("시간 선택", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }

                // 복용 요일
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

                // 저장 버튼
                Section {
                    Button("저장") {
                        saveEditedReminder()
                        onSave?()  // ✅ 저장 후 콜백
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // 삭제 버튼
                Section {
                    Button("알림 삭제") {
                        deleteReminder()
                        onDelete?()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("알림 수정")
            .onAppear {
                editedName = reminder.name
                let calendar = Calendar.current
                var components = DateComponents()
                components.hour = reminder.hour
                components.minute = reminder.minute
                reminderTime = calendar.date(from: components) ?? Date()
                selectedDays = Set(reminder.days)
            }
        }
    }

    func saveEditedReminder() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)

        reminder.name = editedName
        reminder.hour = hour
        reminder.minute = minute
        reminder.days = Array(selectedDays)

        NotificationManager.instance.updateReminder(reminder)
    }

    func deleteReminder() {
        NotificationManager.instance.deleteReminder(id: reminder.id)
    }
}


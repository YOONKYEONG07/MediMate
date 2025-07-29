import SwiftUI
import FirebaseFirestore

struct ReminderEditView: View {
    @Binding var reminder: MedicationReminder
    @Environment(\.presentationMode) var presentationMode

    var onDelete: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil

    @State private var editedName: String = ""
    @State private var reminderTimes: [Date] = [Date()]
    @State private var selectedDays: Set<String> = []

    let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        NavigationView {
            Form {
                // 💊 약 정보
                Section(header: Text("약 정보")) {
                    TextField("약 이름을 입력하세요", text: $editedName)
                }

                // ⏰ 복용 시간 편집
                Section(header: Text("복용 시간")) {
                    Stepper("하루에 \(reminderTimes.count)번 복용해요", value: Binding(
                        get: { reminderTimes.count },
                        set: { newCount in adjustReminderTimes(to: newCount) }
                    ), in: 1...6)

                    ForEach(reminderTimes.indices, id: \.self) { index in
                        DatePicker("복용시간 \(index + 1)", selection: $reminderTimes[index], displayedComponents: .hourAndMinute)
                    }
                }

                // 📅 복용 요일
                Section(header: Text("복용 요일")) {
                    Button(action: {
                        selectedDays = Set(daysOfWeek)
                    }) {
                        Text("매일 알림 받기")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }

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

                // 💾 저장 + ❌ 삭제 버튼
                Section {
                    Button("저장") {
                        saveEditedReminder()
                        onSave?()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .listRowSeparator(.hidden) // ✅ 선 제거

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
                    .padding(.top, 4)
                    .listRowSeparator(.hidden) // ✅ 선 제거
                }
            }
            .navigationTitle("알림 수정")
            .onAppear {
                editedName = reminder.name
                reminderTimes = zip(reminder.hours, reminder.minutes).map { hour, minute in
                    var comp = DateComponents()
                    comp.hour = hour
                    comp.minute = minute
                    return Calendar.current.date(from: comp) ?? Date()
                }
                selectedDays = Set(reminder.days)
            }
        }
    }

    func adjustReminderTimes(to count: Int) {
        while reminderTimes.count < count {
            let offset = TimeInterval(3600 * reminderTimes.count)
            reminderTimes.append(Date().addingTimeInterval(offset))
        }
        while reminderTimes.count > count {
            reminderTimes.removeLast()
        }
    }

    func saveEditedReminder() {
        let calendar = Calendar.current
        let hourArray = reminderTimes.map { calendar.component(.hour, from: $0) }
        let minuteArray = reminderTimes.map { calendar.component(.minute, from: $0) }

        let timesArray: [[String: Int]] = zip(hourArray, minuteArray).map { hour, minute in
            return ["hour": hour, "minute": minute]
        }

        reminder.name = editedName
        reminder.hours = hourArray
        reminder.minutes = minuteArray
        reminder.days = Array(selectedDays)

        NotificationManager.instance.updateReminder(reminder)

        let userID = "testUser123"
        let db = Firestore.firestore()
        db.collection("reminders")
            .whereField("userID", isEqualTo: userID)
            .whereField("medName", isEqualTo: reminder.name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore 수정 실패: \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("⚠️ 수정 대상 문서 없음")
                    return
                }

                db.collection("reminders").document(document.documentID).updateData([
                    "medName": reminder.name,
                    "hours": reminder.hours,
                    "minutes": reminder.minutes,
                    "days": reminder.days,
                    "times": timesArray
                ]) { error in
                    if let error = error {
                        print("❌ Firestore 업데이트 실패: \(error.localizedDescription)")
                    } else {
                        print("✅ Firestore 업데이트 성공")
                    }
                }
            }
    }

    func deleteReminder() {
        NotificationManager.instance.deleteReminder(id: reminder.id)

        let userID = "testUser123"
        let db = Firestore.firestore()
        db.collection("reminders")
            .whereField("userID", isEqualTo: userID)
            .whereField("medName", isEqualTo: reminder.name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore 삭제 실패: \(error.localizedDescription)")
                    return
                }

                for doc in snapshot!.documents {
                    db.collection("reminders").document(doc.documentID).delete { error in
                        if let error = error {
                            print("❌ 삭제 중 에러: \(error.localizedDescription)")
                        } else {
                            print("✅ Firestore 알림 삭제 완료")
                        }
                    }
                }
            }
    }
}


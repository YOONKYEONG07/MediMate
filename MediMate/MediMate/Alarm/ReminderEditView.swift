import SwiftUI
import FirebaseFirestore

struct ReminderEditView: View {
    @Binding var reminder: MedicationReminder
    @Environment(\.presentationMode) var presentationMode

    var onDelete: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil

    @State private var editedName: String = ""
    @State private var reminderTime: Date = Date()
    @State private var selectedDays: Set<String> = []

    let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        NavigationView {
            Form {
                // 💊 약 정보
                Section(header: Text("약 정보")) {
                    TextField("약 이름을 입력하세요", text: $editedName)
                }

                // ⏰ 복용 시간
                Section(header: Text("복용 시간")) {
                    DatePicker("시간 선택", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }

                // 📅 복용 요일
                Section(header: Text("복용 요일")) {
                    Button(action: {
                        selectedDays = Set(daysOfWeek) // 전체 선택
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

                // 💾 저장 버튼
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
                }

                // ❌ 삭제 버튼
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

        // 오늘 요일 추가 보정
        let weekday = calendar.component(.weekday, from: Date()) // 1=일 ~ 7=토
        let today = daysOfWeek[(weekday + 5) % 7]
        if !selectedDays.contains(today) {
            selectedDays.insert(today)
        }

        reminder.name = editedName
        reminder.hour = hour
        reminder.minute = minute
        reminder.days = Array(selectedDays)

        // 🔔 로컬 알림 갱신
        NotificationManager.instance.updateReminder(reminder)

        // ☁️ Firestore 수정 (userID 하드코딩)
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
                    "hour": reminder.hour,
                    "minute": reminder.minute,
                    "days": reminder.days
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
        // 🔔 로컬 삭제
        NotificationManager.instance.deleteReminder(id: reminder.id)

        // ☁️ Firestore 삭제 (userID 하드코딩)
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


import SwiftUI
import FirebaseFirestore

struct ReminderAddView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var medicineName: String = ""
    @State private var reminderTime: Date = Date()
    @State private var selectedDays: Set<String> = []

    let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        NavigationView {
            Form {
                // 💊 약 이름 입력
                Section(header: Text("약 정보")) {
                    TextField("약 이름을 입력하세요", text: $medicineName)
                }

                // ⏰ 복용 시간 선택
                Section(header: Text("복용 시간")) {
                    DatePicker("시간 선택", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }

                // 📅 요일 선택
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

        // 🔥 오늘 요일 포함 안 돼 있으면 자동 추가
        let weekday = calendar.component(.weekday, from: Date()) // 1=일, 2=월, ..., 7=토
        let today = daysOfWeek[(weekday + 5) % 7] // 요일 문자열 변환

        var finalDays = selectedDays
        if !finalDays.contains(today) {
            finalDays.insert(today)
        }

        let reminder = MedicationReminder(
            id: UUID().uuidString,
            name: medicineName,
            hour: hour,
            minute: minute,
            days: Array(finalDays)
        )

        // ✅ 로컬 알림 저장
        NotificationManager.instance.saveReminder(reminder)
        NotificationManager.instance.scheduleNotification(
            title: "\(medicineName) 복용 알림",
            body: String(format: "%02d:%02d 복용 시간입니다!", hour, minute),
            hour: hour,
            minute: minute
        )

        // ✅ Firestore 저장
        let db = Firestore.firestore()
        db.collection("reminders").addDocument(data: [
            "userID": "testUser123", // 실제 로그인 유저 ID로 바꾸기
            "medName": medicineName,
            "hour": hour,
            "minute": minute,
            "days": Array(finalDays)
        ]) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 저장 성공")
            }
        }
    }
}


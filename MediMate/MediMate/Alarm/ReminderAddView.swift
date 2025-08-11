import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ReminderAddView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var medicineName: String = ""
    @State private var selectedDays: Set<String> = []
    @State private var doseCount: Int = 1
    @State private var reminderTimes: [Date] = [Date()]  // 최대 6개까지

    let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]
    var onSave: (() -> Void)? = nil

    var body: some View {
        NavigationView {
            Form {
                // 💊 약 이름
                Section(header: Text("약 정보")) {
                    TextField("약 이름을 입력하세요", text: $medicineName)
                }

                // ⏰ 복용 시간 설정
                Section(header: Text("복용 시간")) {
                    Stepper("하루에 \(doseCount)번 복용해요", value: $doseCount, in: 1...6, onEditingChanged: { _ in
                        adjustReminderTimes()
                    })

                    ForEach(0..<doseCount, id: \.self) { index in
                        DatePicker("복용시간 \(index + 1)", selection: $reminderTimes[index], displayedComponents: .hourAndMinute)
                    }
                }

                // 📅 요일 선택
                Section(header: Text("복용 요일")) {
                    Button("매일 알림 받기") {
                        selectedDays = Set(daysOfWeek)
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
                        onSave?()
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

    // 시간 배열 조정
    func adjustReminderTimes() {
        let baseTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        reminderTimes = (0..<doseCount).map { i in
            Calendar.current.date(byAdding: .hour, value: i * 4, to: baseTime)!
        }
    }

    // 저장 로직
    func saveReminder() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 사용자 없음. Firestore 저장 취소")
            return
        }

        let calendar = Calendar.current
        let finalDays = Array(selectedDays)
        let weekdayInts = finalDays.compactMap { NotificationManager.instance.weekdaySymbolToInt($0) }

        let hourArray = reminderTimes.prefix(doseCount).map { calendar.component(.hour, from: $0) }
        let minuteArray = reminderTimes.prefix(doseCount).map { calendar.component(.minute, from: $0) }

        // 🔔 각 시간마다 알림 등록
        for (hour, minute) in zip(hourArray, minuteArray) {
            let idPrefix = "\(medicineName)_\(hour)_\(minute)"
            NotificationManager.instance.scheduleNotification(
                title: "\(medicineName) 복용 알림",
                body: String(format: "%02d:%02d 복용 시간입니다!", hour, minute),
                hour: hour,
                minute: minute,
                weekdays: weekdayInts,
                idPrefix: idPrefix
            )
        }

        // ✅ 하나의 MedicationReminder로 저장
        let reminder = MedicationReminder(
            id: medicineName,
            name: medicineName,
            hours: hourArray,
            minutes: minuteArray,
            days: finalDays
        )
        NotificationManager.instance.saveGroupedReminder(reminder)
        NotificationManager.instance.saveReminder(reminder)

        // Firestore 저장
        let times: [[String: Int]] = zip(hourArray, minuteArray).map { ["hour": $0, "minute": $1] }

        let db = Firestore.firestore()
        db.collection("reminders").addDocument(data: [
            "userID": userID,
            "medName": medicineName,
            "days": finalDays,
            "times": times
        ]) { error in
            if let error = error {
                print("Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("Firestore 저장 성공")
            }
        }
    }
}


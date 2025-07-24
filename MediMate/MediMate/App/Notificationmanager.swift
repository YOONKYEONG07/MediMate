import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let instance = NotificationManager()

    private let reminderKey = "reminderList"

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 알림 권한 허용됨")
                self.registerNotificationActions()
            } else {
                print("❌ 알림 권한 거부됨")
            }
        }
    }

    func registerNotificationActions() {
        let takeAction = UNNotificationAction(
            identifier: "TAKE_MEDICINE",
            title: "💊 복용함",
            options: [.foreground]
        )

        let skipAction = UNNotificationAction(
            identifier: "SKIP_MEDICINE",
            title: "⏰ 복용 안함",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "MEDICINE_REMINDER",
            actions: [takeAction, skipAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // ✅ 반복 알림 예약 (요일 + 시간)
    func scheduleNotification(title: String, body: String, hour: Int, minute: Int, weekdays: [Int], idPrefix: String) {
        let center = UNUserNotificationCenter.current()

        for weekday in weekdays {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = weekday  // 1=일, 2=월, ..., 7=토

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let id = "\(idPrefix)_\(hour)_\(minute)_\(weekday)"  // 고유 ID
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "MEDICINE_REMINDER"

            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("❌ 알림 등록 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 반복 알림 등록: \(id)")
                }
            }
        }
    }

    // 🔁 한글 요일 → Int (1~7)
    func weekdaySymbolToInt(_ symbol: String) -> Int? {
        let map: [String: Int] = ["일": 1, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7]
        return map[symbol]
    }

    // ✅ 리마인드 알림 (복용 안함 눌렀을 때)
    func scheduleReminderAfterSkip(title: String, body: String, afterMinutes: Int = 30) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MEDICINE_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterMinutes * 60), repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 리마인드 알림 실패: \(error)")
            } else {
                print("✅ 리마인드 알림 예약됨 (⏰ \(afterMinutes)분 후)")
            }
        }
    }

    // ✅ 알림 응답 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let name = response.notification.request.content.title
            .replacingOccurrences(of: " 복약 알림", with: "")

        let isTaken = response.actionIdentifier == "TAKE_MEDICINE"
        let record = DoseRecord(
            id: UUID().uuidString,
            medicineName: name,
            takenTime: Date(),
            taken: isTaken
        )
        DoseHistoryManager.shared.saveRecord(record)

        if !isTaken {
            // 30분 후 리마인드
            self.scheduleReminderAfterSkip(title: "\(name) 복약 리마인드", body: "💊 복용 안하셨나요? 잊지 말고 드세요!")
        }

        print("💾 복약 기록 저장됨: \(name) - \(isTaken ? "복용함" : "복용 안함")")
        completionHandler()
    }

    // ✅ 오늘 요일에 해당하는 알림만 불러오기
    func loadReminders(for date: Date = Date()) -> [MedicationReminder] {
        guard let data = UserDefaults.standard.data(forKey: reminderKey),
              let decoded = try? JSONDecoder().decode([MedicationReminder].self, from: data) else {
            return []
        }

        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date)  // 1: 일 ~ 7: 토
        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        let todaySymbol = weekdaySymbols[weekdayIndex - 1]

        return decoded.filter { $0.days.contains(todaySymbol) }
    }

    // ✅ 모든 알림 불러오기 (중복 체크용)
    func loadAllReminders() -> [MedicationReminder] {
        guard let data = UserDefaults.standard.data(forKey: reminderKey),
              let decoded = try? JSONDecoder().decode([MedicationReminder].self, from: data) else {
            return []
        }
        return decoded
    }
    func saveGroupedReminder(_ reminder: MedicationReminder) {
        var current = loadAllReminders()
        
        // ✅ 같은 약 이름이면 덮어쓰기 (하나만 유지)
        current.removeAll { $0.name == reminder.name }

        current.append(reminder)

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: reminderKey)
        }
    }

    // ✅ 중복 저장 방지를 위해 수정
    func saveReminder(_ reminder: MedicationReminder) {
        var current = loadAllReminders()

        // 동일한 ID 알림이 없으면 추가
        if !current.contains(where: { $0.id == reminder.id }) {
            current.append(reminder)

            if let encoded = try? JSONEncoder().encode(current) {
                UserDefaults.standard.set(encoded, forKey: reminderKey)
            }
        }
    }

    // ✅ 알림 삭제
    func deleteReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        var current = loadAllReminders()
        current.removeAll { $0.id == id }

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: reminderKey)
        }
    }

    // ✅ 알림 수정
    func updateReminder(_ updated: MedicationReminder) {
        deleteReminder(id: updated.id)
        saveReminder(updated)
    }
}


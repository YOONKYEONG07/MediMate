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

    // ✅ 일반 알림 예약
    func scheduleNotification(title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MEDICINE_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 알림 등록 실패: \(error)")
            } else {
                print("✅ 알림 등록 성공: \(hour):\(minute)")
            }
        }
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

    // ✅ 저장된 알림 불러오기
    func loadReminders(for date: Date = Date()) -> [MedicationReminder] {
        guard let data = UserDefaults.standard.data(forKey: reminderKey),
              let decoded = try? JSONDecoder().decode([MedicationReminder].self, from: data) else {
            return []
        }

        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date)  // 1: 일 ~ 7: 토
        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        let todaySymbol = weekdaySymbols[weekdayIndex - 1]  // 오늘 요일 한글

        return decoded.filter { reminder in
            // 오늘 요일에 포함된 약만 필터링
            reminder.days.contains(todaySymbol)
        }
    }


    // ✅ 알림 저장
    func saveReminder(_ reminder: MedicationReminder) {
        var current = loadReminders()
        current.append(reminder)

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: reminderKey)
        }
    }

    // ✅ 알림 삭제
    func deleteReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        var current = loadReminders()
        current.removeAll { $0.id == id }

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: reminderKey)
        }
    }
    // ✅ 알림 수정
    func updateReminder(_ updated: MedicationReminder) {
        deleteReminder(id: updated.id)           // 기존 알림 제거
        saveReminder(updated)                    // 새로운 데이터 저장
        scheduleNotification(                    // 다시 알림 등록
            title: "\(updated.name) 복약 알림",
            body: "약 복용 시간이에요!",
            hour: updated.hour,
            minute: updated.minute
        )
    }

}


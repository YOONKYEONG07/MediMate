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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 알림 권한 허용됨")
                self.registerNotificationActions()
            } else {
                print("❌ 알림 권한 거부됨")
            }
        }
    }

    func registerNotificationActions() {
        let takeAction = UNNotificationAction(identifier: "TAKE_MEDICINE", title: "💊 복용함", options: [.foreground])
        let skipAction = UNNotificationAction(identifier: "SKIP_MEDICINE", title: "⏰ 복용 안함", options: [])

        let category = UNNotificationCategory(
            identifier: "MEDICINE_REMINDER",
            actions: [takeAction, skipAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // ✅ 반복 알림 예약
    func scheduleNotification(title: String, body: String, hour: Int, minute: Int, weekdays: [Int], idPrefix: String) {
        let center = UNUserNotificationCenter.current()

        for weekday in weekdays {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = weekday

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let id = "\(idPrefix)_\(hour)_\(minute)_\(weekday)"

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

    func weekdaySymbolToInt(_ symbol: String) -> Int? {
        let map = ["일": 1, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7]
        return map[symbol]
    }

    // ✅ 복용 안함 시 리마인드
    func scheduleReminderAfterSkip(title: String, body: String, afterMinutes: Int = 30) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MEDICINE_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterMinutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

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
            .replacingOccurrences(of: "💊 ", with: "")
            .replacingOccurrences(of: " 복용 알림", with: "")
            .replacingOccurrences(of: "복약 리마인드", with: "")

        let isTaken = response.actionIdentifier == "TAKE_MEDICINE"
        let record = DoseRecord(id: UUID().uuidString, medicineName: name, takenTime: Date(), taken: isTaken)
        DoseHistoryManager.shared.saveRecord(record)

        if !isTaken {
            scheduleReminderAfterSkip(
                title: "💊 복약 리마인드",
                body: "\(name)을 아직 복용하지 않으셨어요! 잊지 말고 드세요!"
            )
        }

        print("💾 복약 기록 저장됨: \(name) - \(isTaken ? "복용함" : "복용 안함")")
        completionHandler()
    }

    func loadReminders(for date: Date = Date()) -> [MedicationReminder] {
        guard let data = UserDefaults.standard.data(forKey: reminderKey),
              let decoded = try? JSONDecoder().decode([MedicationReminder].self, from: data) else {
            return []
        }

        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        let weekdayIndex = Calendar.current.component(.weekday, from: date)
        let todaySymbol = weekdaySymbols[weekdayIndex - 1]

        return decoded.filter { $0.days.contains(todaySymbol) }
    }

    func loadAllReminders() -> [MedicationReminder] {
        guard let data = UserDefaults.standard.data(forKey: reminderKey),
              let decoded = try? JSONDecoder().decode([MedicationReminder].self, from: data) else {
            return []
        }
        return decoded
    }

    func saveGroupedReminder(_ reminder: MedicationReminder) {
        var current = loadAllReminders()
        current.removeAll { $0.name == reminder.name }
        current.append(reminder)

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: reminderKey)
        }
    }

    func saveReminder(_ reminder: MedicationReminder) {
        var current = loadAllReminders()

        if !current.contains(where: { $0.id == reminder.id }) {
            current.append(reminder)
            if let encoded = try? JSONEncoder().encode(current) {
                UserDefaults.standard.set(encoded, forKey: reminderKey)
            }
        }
    }

    func deleteReminder(id: String) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        var current = loadAllReminders()
        current.removeAll { $0.id == id }

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: reminderKey)
        }
    }

    func updateReminder(_ updated: MedicationReminder) {
        let allIDs = generateNotificationIDs(for: updated)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIDs)

        var current = loadAllReminders()
        current.removeAll { $0.id == updated.id }
        current.append(updated)

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: reminderKey)
        }

        let weekdays = updated.days.compactMap { weekdaySymbolToInt($0) }

        for (hour, minute) in zip(updated.hours, updated.minutes) {
            let timeText = String(format: "%02d:%02d", hour, minute)
            scheduleNotification(
                title: "💊 \(updated.name) 복용 알림",
                body: "\(timeText) 복용 시간입니다!",
                hour: hour,
                minute: minute,
                weekdays: weekdays,
                idPrefix: "reminder_\(updated.id)"
            )
        }
    }

    private func generateNotificationIDs(for reminder: MedicationReminder) -> [String] {
        let weekdays = reminder.days.compactMap { weekdaySymbolToInt($0) }
        return weekdays.flatMap { weekday in
            zip(reminder.hours, reminder.minutes).map { hour, minute in
                "reminder_\(reminder.id)_\(hour)_\(minute)_\(weekday)"
            }
        }
    }
}



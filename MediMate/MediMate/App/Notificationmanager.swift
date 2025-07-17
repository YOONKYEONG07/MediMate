import UserNotifications
import Foundation

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let instance = NotificationManager()

    private let key = "reminderList"

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨 ✅")
                self.registerNotificationActions()
            } else {
                print("알림 권한 거부됨 ❌")
            }
        }
        center.delegate = self
    }

    func registerNotificationActions() {
        let takeAction = UNNotificationAction(
            identifier: "TAKE_MEDICINE",
            title: "약 복용",
            options: [.authenticationRequired]
        )

        let skipAction = UNNotificationAction(
            identifier: "SKIP_MEDICINE",
            title: "복용 안함",
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

    func scheduleNotification(title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MEDICINE_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 등록 실패: \(error)")
            } else {
                print("알림 등록 성공 🕒 \(hour):\(minute)")
            }
        }
    }

    func loadReminders() -> [MedicationReminder] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([MedicationReminder].self, from: data) else {
            return []
        }
        return decoded
    }

    func saveReminder(_ reminder: MedicationReminder) {
        var current = loadReminders()
        current.append(reminder)

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func deleteReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        var current = loadReminders()
        current.removeAll { $0.id == id }

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let name = response.notification.request.content.title.replacingOccurrences(of: " 복약 알림", with: "")

        let record = DoseRecord(
            id: UUID().uuidString,
            medicineName: name,
            takenTime: Date(),
            taken: response.actionIdentifier == "TAKE_MEDICINE"
        )
        DoseHistoryManager.shared.saveRecord(record)
        let status = record.taken ? "복용" : "복용안함"
        print("✅ 복약 기록 저장: \(status)")
        completionHandler()
    }
}

class DoseHistoryManager {
    static let shared = DoseHistoryManager()
    private let key = "doseHistory"

    func saveRecord(_ record: DoseRecord) {
        var records = loadRecords()
        records.append(record)

        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadRecords() -> [DoseRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DoseRecord].self, from: data) else {
            return []
        }
        return decoded
    }
}

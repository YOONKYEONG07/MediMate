import UserNotifications
import Foundation

class NotificationManager {
    static let instance = NotificationManager()
    
    private let key = "reminderList"
    
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨 ✅")
            } else {
                print("알림 권한 거부됨 ❌")
            }
        }
    }

    func scheduleNotification(title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

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

        // 알림 저장
    func saveReminder(_ reminder: MedicationReminder) {
        var current = loadReminders()
        current.append(reminder)

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    // 알림 삭제
    func deleteReminder(id: String) {
        // 알림 제거
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        // 로컬에서도 제거
        var current = loadReminders()
        current.removeAll { $0.id == id }

        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
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


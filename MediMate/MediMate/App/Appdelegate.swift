import UIKit
import Firebase
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // ✅ delegate는 반드시 여기서 지정
        UNUserNotificationCenter.current().delegate = NotificationManager.instance

        // ✅ 권한 요청하면 내부에서 register도 처리됨
        NotificationManager.instance.requestAuthorization()

        return true
    }
}


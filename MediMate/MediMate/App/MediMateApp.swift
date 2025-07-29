import SwiftUI
import Firebase

@main
struct MediMate: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false  // 🔹 자동 로그인 상태 저장 변수 추가

    init() {
        FirebaseApp.configure()
        NotificationManager.instance.requestAuthorization()
        NotificationManager.instance.registerNotificationActions()
        UNUserNotificationCenter.current().delegate = NotificationManager.instance
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MyPage()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            } else {
                LoginView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }
 }
   

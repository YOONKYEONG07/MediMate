import SwiftUI
import Firebase

@main
struct MediMate: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("isDarkMode") private var isDarkMode = false  // 다크모드 상태 저장

    init() {
        FirebaseApp.configure()
        NotificationManager.instance.requestAuthorization()
        NotificationManager.instance.registerNotificationActions()
        UNUserNotificationCenter.current().delegate = NotificationManager.instance
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)  // 다크모드 적용
            } else {
                LoginView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)  // 로그인 화면도 다크모드 적용
            }
        }
    }
}

import SwiftUI
import Firebase

@main
struct MediMate: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    init() {
        FirebaseApp.configure()
        NotificationManager.instance.requestAuthorization()
        NotificationManager.instance.registerNotificationActions()
        UNUserNotificationCenter.current().delegate = NotificationManager.instance
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()  // ✅ 로그인된 경우: TabView 포함된 메인 화면
            } else {
                LoginView()  // ✅ 로그인 안 된 경우: 로그인 화면
            }
        }
    }
}

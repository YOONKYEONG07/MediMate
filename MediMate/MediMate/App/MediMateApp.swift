import SwiftUI
import Firebase

@main
struct MediMate: App {
    @AppStorage("isDarkMode") private var isDarkMode = false  // ✅ 추가

    init() {
        FirebaseApp.configure()
        NotificationManager.instance.requestAuthorization()
        
        NotificationManager.instance.registerNotificationActions()
           UNUserNotificationCenter.current().delegate = NotificationManager.instance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

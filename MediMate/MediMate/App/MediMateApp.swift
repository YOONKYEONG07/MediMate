import SwiftUI
import Firebase

@main
struct MediMate: App {
    @AppStorage("isDarkMode") private var isDarkMode = false  // ✅ 추가

    init() {
        FirebaseApp.configure()
        NotificationManager.instance.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

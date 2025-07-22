import SwiftUI
import Firebase

@main
struct MediMate: App {
    init() {
        FirebaseApp.configure()
        NotificationManager.instance.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

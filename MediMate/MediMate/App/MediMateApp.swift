import SwiftUI
import Firebase

@main
struct MediMate: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView(isLoggedIn: $isLoggedIn, isDarkMode: $isDarkMode)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

struct RootView: View {
    @Binding var isLoggedIn: Bool
    @Binding var isDarkMode: Bool

    var body: some View {
        Group {
            if isLoggedIn {
                ContentView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Firebase 로그인 상태와 isLoggedIn 동기화
            isLoggedIn = Auth.auth().currentUser != nil
        }
    }
}

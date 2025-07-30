import SwiftUI
import Firebase
import FirebaseAuth

@main
struct MediMate: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("isDarkMode") private var isDarkMode = false

 feature/backend-mypage/52
    // ✅ 사용자 세션 객체 생성
    @StateObject var userSession = UserSession()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
//        FirebaseApp.configure()
    }


 main
    var body: some Scene {
        WindowGroup {
            // ✅ 여기서 environmentObject 주입!
            RootView(isLoggedIn: $isLoggedIn, isDarkMode: $isDarkMode)
                .environmentObject(userSession)
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
            // ✅ 알림 권한 요청
            NotificationManager.instance.requestAuthorization()

            // Firebase 로그인 상태와 isLoggedIn 동기화
            isLoggedIn = Auth.auth().currentUser != nil
        }
    }
}


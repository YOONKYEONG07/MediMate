import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var selectedTab = 0
    @StateObject private var chatInputManager = ChatInputManager()

    var body: some View {
        if isLoggedIn {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .environmentObject(chatInputManager)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("홈")
                    }
                    .tag(0)

                ReminderTabView()
                    .tabItem {
                        Image(systemName: "alarm.fill")
                        Text("알림")
                    }
                    .tag(1)

                AnalyzeView()
                    .tabItem {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("분석")
                    }
                    .tag(2)

                ConsultView()
                    .environmentObject(chatInputManager)
                    .tabItem {
                        Image(systemName: "message.fill")
                        Text("상담")
                    }
                    .tag(3)

                MyPage()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("마이페이지")
                    }
                    .tag(4)
            }
        } else {
            LoginView()
        }
    }
}

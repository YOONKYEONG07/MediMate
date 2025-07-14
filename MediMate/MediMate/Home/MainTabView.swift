import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var chatInputManager = ChatInputManager()  // ✅ 추가됨

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)  // ✅ 바인딩 넘김
                .environmentObject(chatInputManager)  // ✅ 챗뷰에도 넘기기
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(0)

            ReportView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("리포트")
                }
                .tag(1)

            ChatView()
                .environmentObject(chatInputManager)
                .tabItem {
                    Label("챗봇", systemImage: "message")
                }
                .tag(3)
        }
    }
}


import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("홈")
                    }   

                ReminderTabView()
                    .tabItem {
                        Image(systemName: "alarm.fill")
                        Text("알림")
                    }

                AnalyzeView()
                    .tabItem {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("분석")
                    }

                ConsultView()
                    .tabItem {
                        Image(systemName: "message.fill")
                        Text("상담")
                    }

                MyPage()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("마이페이지")
                    }
            }
        } else {
            LoginView() 
        }
    }
}

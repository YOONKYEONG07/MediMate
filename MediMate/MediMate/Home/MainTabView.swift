import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }

            ReportView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("리포트")
                }
        }
    }
}


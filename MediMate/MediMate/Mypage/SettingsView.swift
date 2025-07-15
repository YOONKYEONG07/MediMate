import SwiftUI
//커밋 테스트용 주석입니다.
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) var systemColorScheme
    @Environment(\.openURL) var openURL

    var body: some View {
        Form {
            // 1. 계정
            Section(header: Text("계정")) {
                NavigationLink("비밀번호 변경", destination: ChangePasswordView())
            }

//            // 2. 알림
//            Section(header: Text("알림")) {
//                NavigationLink("알림 설정", destination: NotificationSettingsView())
//            }

            // 3. 다크모드
            Section(header: Text("화면")) {
                Toggle(isOn: $isDarkMode) {
                    Label("다크모드", systemImage: "moon.fill")
                }
            }

            // 4. 앱 정보
            Section(header: Text("앱 정보")) {
                HStack {
                    Text("버전")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }

            // 5. 데이터 및 보안
            Section(header: Text("데이터 및 보안")) {
                NavigationLink("개인정보 처리방침", destination: PrivacyPolicyView())
                Button("데이터 초기화", role: .destructive) {
                    resetUserData()
                }
            }

            // 6. 문의 및 피드백
            Section(header: Text("문의 및 피드백")) {
                Button("이메일로 문의하기") {
                    openURL(URL(string: "mailto:support@medimate.com")!)
                }
                NavigationLink("피드백 보내기", destination: FeedbackFormView())
            }
        }
        .navigationTitle("환경설정")
    }

    func resetUserData() {
        // 예시: UserDefaults 초기화
        let keys = ["nickname", "gender", "height", "weight", "birthday"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
                                if let url = URL(string: "mailto:medimate.help@gmail.com") {
                                    openURL(url)//시뮬레이터에서는 작동 x
                                }
                            }
                NavigationLink("피드백 보내기", destination: FeedbackFormView())
            }
        }
        .navigationTitle("환경설정")
    }

    func resetUserData() {
        // 🔸 1. Firestore 사용자 문서 초기화
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 사용자 없음")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        userRef.updateData([
            "nickname": "",
            "birthday": "",
            "gender": "선택 안 함",
            "height": "",
            "weight": ""
        ]) { error in
            if let error = error {
                print("❌ Firestore 초기화 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 사용자 데이터 초기화 완료")
            }
        }

        // 🔸 2. UserDefaults 초기화
        let keys = ["nickname", "gender", "height", "weight", "birthday"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }

        print("✅ UserDefaults 초기화 완료")
    }

}

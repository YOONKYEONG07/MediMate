import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // 앱 로고
            VStack(spacing: 8) {
                Image(systemName: "pills.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)

                Text("MediMate")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }

            // 구글 로그인 버튼 (텍스트 포함)
            Button(action: {
                authVM.signInWithGoogle { success in
                    if success {
                        isLoggedIn = true
                    }
                }
            }) {
                Image("google-icon") // ✅ '구글 계정으로 가입하기' 텍스트 포함된 이미지
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 50)
            }

            Spacer()
        }
        .padding()
    }
}

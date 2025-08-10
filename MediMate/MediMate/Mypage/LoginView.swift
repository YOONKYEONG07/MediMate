import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        VStack(spacing: 10) {
            Spacer()

            // 앱 로고
            VStack(spacing: 10) {
                Image("SignIn_Logo")
                    .resizable()
                    .frame(width: 250, height: 250)
                    .foregroundColor(.blue)
//
//                Text("MediMate")
//                    .font(.largeTitle)
//                    .fontWeight(.semibold)
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

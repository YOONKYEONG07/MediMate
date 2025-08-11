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
                Image("google-icon") // Google Sign-in 버튼
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 50)
            }

            Spacer()
        }
        .padding()
    }
}

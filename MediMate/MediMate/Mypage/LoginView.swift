import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("MediMate")
                .font(.largeTitle)
                .bold()

            Text("Google 계정으로 로그인해 주세요")
                .foregroundColor(.gray)

            // ✅ Google 로그인 버튼
            Button(action: {
                authVM.signInWithGoogle { success in
                    if success {
                        isLoggedIn = true
                    }
                }
            }) {
                HStack {
                    Image("googleLogo")  // Assets에 있는 구글 로고 이미지
                        .resizable()
                        .frame(width: 20, height: 20)

                    Text("Google 계정으로 가입 및 로그인")
                        .foregroundColor(.black)
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
            }

            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}

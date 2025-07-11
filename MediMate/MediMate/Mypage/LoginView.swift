import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @StateObject private var authVM = AuthViewModel()

    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer() // 상단 여백 추가

                Text("로그인")
                    .font(.largeTitle)
                    .bold()

                TextField("이메일", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("비밀번호", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.oneTimeCode)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)

                if !authVM.errorMessage.isEmpty {
                    Text(authVM.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("로그인") {
                    authVM.login(email: email, password: password)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                NavigationLink(destination: Signup(), isActive: $showSignup) {
                    Button("회원가입") {
                        showSignup = true
                    }
                }
                .padding(.top, 8)

                Spacer() // 👈 하단 여백 (중앙 정렬 완성)
            }
            .padding()
        }
        .onChange(of: authVM.user) { user in
            if user != nil {
                isLoggedIn = true
            }
        }
    }
}

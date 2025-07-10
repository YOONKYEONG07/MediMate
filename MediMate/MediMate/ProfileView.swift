import SwiftUI

struct ProfileView: View {
    @StateObject var authVM = AuthViewModel()

    @State private var email = ""
    @State private var password = ""
    @State private var isRegisterMode = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authVM.user {
                    Text("👋 환영합니다, \(user.email ?? "사용자")님")
                        .font(.title2)
                    Button("로그아웃") {
                        authVM.logout()
                    }
                    .foregroundColor(.red)
                } else {
                    VStack(spacing: 15) {
                        Text(isRegisterMode ? "회원가입" : "로그인")
                            .font(.title).bold()

                        TextField("이메일", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)

                        SecureField("비밀번호", text: $password)
                            .textFieldStyle(.roundedBorder)

                        Button(isRegisterMode ? "회원가입" : "로그인") {
                            if isRegisterMode {
                                authVM.register(email: email, password: password)
                            } else {
                                authVM.login(email: email, password: password)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button(isRegisterMode ? "이미 계정이 있어요" : "회원가입하기") {
                            isRegisterMode.toggle()
                        }
                        .font(.caption)
                    }
                }

                if !authVM.errorMessage.isEmpty {
                    Text(authVM.errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("마이페이지")
        }
    }
}


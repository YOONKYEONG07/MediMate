import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false

    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var showSignup = false  // 회원가입 화면 표시 여부

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("로그인")
                    .font(.largeTitle)
                    .bold()

                TextField("이메일", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("비밀번호", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.oneTimeCode) // 자동 완성/자동 생성 방지
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)


                if showError {
                    Text("이메일 또는 비밀번호가 올바르지 않습니다.")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("로그인") {
                    if email == "test@email.com" && password == "1234" {
                        isLoggedIn = true
                    } else {
                        showError = true
                    }
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

                Spacer()
            }
            .padding()
        }
    }
}

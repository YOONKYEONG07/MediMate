import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Signup: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @StateObject var authVM = AuthViewModel()

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("회원가입")
                .font(.largeTitle)

            TextField("이메일", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.emailAddress)

            SecureField("비밀번호", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.oneTimeCode) // 자동완성 방지용

            SecureField("비밀번호 확인", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.oneTimeCode) // 자동완성 방지용


            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button("가입하기") {
                if password == confirmPassword {
                    authVM.register(email: email, password: password) { success in
                        if success {
                            isLoggedIn = true
                        }
                    }
                    errorMessage = ""
                } else {
                    errorMessage = "비밀번호가 일치하지 않습니다."
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false

    var body: some View {
        Form {
            Section(header: Text("현재 비밀번호")) {
                SecureField("현재 비밀번호 입력", text: $currentPassword)
            }

            Section(header: Text("새 비밀번호")) {
                SecureField("새 비밀번호 입력", text: $newPassword)
                SecureField("새 비밀번호 확인", text: $confirmPassword)
            }

            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button("비밀번호 변경") {
                changePassword()
            }
            .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
        }
        .navigationTitle("비밀번호 변경")
        .alert("성공", isPresented: $showSuccess) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("비밀번호가 성공적으로 변경되었습니다.")
        }
    }

    func changePassword() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "로그인된 사용자가 없습니다."
            showError = true
            return
        }

        guard let email = user.email else {
            errorMessage = "이메일 정보를 가져올 수 없습니다."
            showError = true
            return
        }

        print("로그인된 이메일: \(email)")
        print("입력한 현재 비밀번호: \(currentPassword)")

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        // 1. 비밀번호 재인증
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                errorMessage = "현재 비밀번호가 올바르지 않거나 만료되었습니다.\n(\(error.localizedDescription))"
                showError = true
                return
            }

            // 2. 새 비밀번호 일치 여부 확인
            guard newPassword == confirmPassword else {
                errorMessage = "새 비밀번호가 일치하지 않습니다."
                showError = true
                return
            }

            // 3. 새 비밀번호 업데이트
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    errorMessage = "비밀번호 변경 실패: \(error.localizedDescription)"
                    showError = true
                    return
                }

                // 성공 처리
                showError = false
                showSuccess = true
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            }
        }
    }
}

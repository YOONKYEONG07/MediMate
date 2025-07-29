import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation

class AuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""

    // 로그인
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = ""
                    completion(true)
                }
            }
        }
    }

    // 회원가입
    func register(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
                return
            }
            // 회원가입 성공 시 추가 작업 가능
            completion(true)
        }
    }

    // 재인증 (이메일+비밀번호)
    func reauthenticate(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "로그인된 사용자가 없습니다.")
            return
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }

    // 재인증 후 회원 탈퇴
    func deleteUser(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        reauthenticate(email: email, password: password) { success, errorMsg in
            if success {
                Auth.auth().currentUser?.delete { error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        completion(true, nil)
                    }
                }
            } else {
                completion(false, errorMsg)
            }
        }
    }
}

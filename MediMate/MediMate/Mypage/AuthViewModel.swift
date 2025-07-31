import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

class AuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""

    // ✅ 1. 구글 로그인
    func signInWithGoogle(completion: @escaping (Bool) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Missing Google Client ID"
            completion(false)
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(false)
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Google ID Token missing"
                completion(false)
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                // ✅ Firestore에 유저 정보 저장
                if let uid = authResult?.user.uid {
                    let db = Firestore.firestore()
                    db.collection("users").document(uid).setData([
                        "email": user.profile?.email ?? "",
                        "name": user.profile?.name ?? "",
                        "createdAt": Timestamp()
                    ], merge: true)
                }

                completion(true)
            }
        }
    }

    // ✅ 2. 이메일/비밀번호 회원가입
    func register(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
                return
            }

            if let uid = result?.user.uid {
                let db = Firestore.firestore()
                db.collection("users").document(uid).setData([
                    "email": email,
                    "createdAt": Timestamp()
                ], merge: true)
            }

            DispatchQueue.main.async {
                self.errorMessage = ""
                completion(true)
            }
        }
    }

    // ✅ 3. 회원 탈퇴
    func deleteUser(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(false, "재인증 실패: \(error.localizedDescription)")
                return
            }

            Auth.auth().currentUser?.delete { error in
                if let error = error {
                    completion(false, "탈퇴 실패: \(error.localizedDescription)")
                } else {
                    completion(true, nil)
                }
            }
        }
    }
}

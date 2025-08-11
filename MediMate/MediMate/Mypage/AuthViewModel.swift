import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

class AuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""

    // 1. 구글 로그인
    func signInWithGoogle(completion: @escaping (Bool) -> Void) {
        guard FirebaseApp.app()?.options.clientID != nil else {
            self.errorMessage = "Missing Google Client ID"
            completion(false)
            return
        }


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

                if let uid = authResult?.user.uid {
                    let db = Firestore.firestore()
                    db.collection("users").document(uid).setData([
                        "email": user.profile?.email ?? "",
                        "name": user.profile?.name ?? "",
                        "createdAt": Timestamp()
                    ], merge: true)
                }
                
                // ✅ 🔔 알림 복원 추가
                   NotificationManager.instance.restoreRemindersAfterLogin()

                completion(true)
            }
        }
    }

    // 2. 이메일/비밀번호 회원가입
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

    // 3. 구글 로그인 사용자 탈퇴
    func deleteGoogleUser(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "로그인된 사용자가 없습니다.")
            return
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(false, "Google Client ID가 없습니다.")
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(false, "루트 뷰 컨트롤러를 찾을 수 없습니다.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                completion(false, "Google 재로그인 실패: \(error.localizedDescription)")
                return
            }

            guard let googleUser = result?.user,
                  let idToken = googleUser.idToken?.tokenString else {
                completion(false, "토큰 정보가 없습니다.")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: googleUser.accessToken.tokenString)

            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    completion(false, "재인증 실패: \(error.localizedDescription)")
                    return
                }

                let uid = user.uid
                let db = Firestore.firestore()

                db.collection("users").document(uid).delete { error in
                    if let error = error {
                        completion(false, "Firestore 삭제 실패: \(error.localizedDescription)")
                        return
                    }

                    user.delete { error in
                        if let error = error {
                            completion(false, "계정 삭제 실패: \(error.localizedDescription)")
                        } else {
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }
}

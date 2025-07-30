import Foundation
import FirebaseAuth
import Firebase
import GoogleSignIn
import GoogleSignInSwift
import UIKit

class AuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""

    func signInWithGoogle(completion: @escaping (Bool) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "❌ Firebase clientID를 찾을 수 없습니다."
            completion(false)
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "❌ Root ViewController를 찾을 수 없습니다."
            completion(false)
            return
        }

        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                self.errorMessage = "❌ Google 로그인 실패: \(error.localizedDescription)"
                completion(false)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.errorMessage = "❌ 사용자 토큰을 가져올 수 없습니다."
                completion(false)
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    self.errorMessage = "❌ Firebase 로그인 실패: \(error.localizedDescription)"
                    completion(false)
                } else {
                    self.errorMessage = ""
                    completion(true)
                }
            }
        }
    }

    func deleteUser(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "사용자 정보 없음")
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(false, "재인증 실패: \(error.localizedDescription)")
                return
            }

            user.delete { error in
                if let error = error {
                    completion(false, "삭제 실패: \(error.localizedDescription)")
                } else {
                    completion(true, nil)
                }
            }
        }
    }
}

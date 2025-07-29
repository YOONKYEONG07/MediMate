import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation

class AuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""

    // 🔹 로그인
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

    // 🔹 회원가입
    func register(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
                return
            }

            guard let user = result?.user else {
                completion(false)
                return
            }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "email": email,
                "createdAt": Timestamp()
            ]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        self.errorMessage = ""
                        completion(true)
                    }
                }
            }
        }
    }
}

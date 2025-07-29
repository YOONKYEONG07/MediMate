import Foundation
import FirebaseAuth
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String = ""

    // 자동로그인 상태를 SwiftUI와 공유
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    init() {
        self.user = Auth.auth().currentUser
    }

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            self.user = result?.user
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
    }

    func register(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            self.user = result?.user
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

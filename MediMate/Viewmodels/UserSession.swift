import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserSession: ObservableObject {
    @Published var uid: String = ""
    @Published var email: String = ""

    private var db = Firestore.firestore()

    init() {
        if let user = Auth.auth().currentUser {
            self.uid = user.uid
            self.email = user.email ?? ""
        }
    }

    // 즐겨찾기 약 목록 불러오기
    func fetchFavorites(completion: @escaping ([String]) -> Void) {
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let meds = document.data()?["favoriteMeds"] as? [String] ?? []
                completion(meds)
            } else {
                completion([])
            }
        }
    }

    // 즐겨찾기 약 목록 저장하기
    func saveFavorites(_ meds: [String]) {
        db.collection("users").document(uid).setData(["favoriteMeds": meds], merge: true)
    }
}

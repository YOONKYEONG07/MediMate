import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseHelper {
    static let shared = FirebaseHelper()
    private let db = Firestore.firestore()

    private init() {}

    // 🔹 사용자 프로필 저장
    func saveUserProfile(nickname: String, birthday: String, gender: String, height: String, weight: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 사용자 없음")
            completion(false)
            return
        }

        let data: [String: Any] = [
            "nickname": nickname,
            "birthday": birthday,
            "gender": gender,
            "height": height,
            "weight": weight
        ]

        db.collection("users").document(uid).setData(data, merge: true) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Firestore 저장 성공")
                completion(true)
            }
        }
    }

    // 🔹 사용자 프로필 불러오기
    func loadUserProfile(completion: @escaping (_ nickname: String?, _ birthday: String?, _ gender: String?, _ height: String?, _ weight: String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 사용자 없음")
            completion(nil, nil, nil, nil, nil)
            return
        }

        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("❌ Firestore 불러오기 실패: \(error.localizedDescription)")
                completion(nil, nil, nil, nil, nil)
                return
            }

            guard let data = document?.data() else {
                completion(nil, nil, nil, nil, nil)
                return
            }

            let nickname = data["nickname"] as? String
            let birthday = data["birthday"] as? String
            let gender = data["gender"] as? String
            let height = data["height"] as? String
            let weight = data["weight"] as? String

            completion(nickname, birthday, gender, height, weight)
        }
    }
}

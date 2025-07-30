import Foundation
import FirebaseFirestore

class ChatFirestoreManager {
    private let db = Firestore.firestore()

    // MARK: - 1. 메시지 저장
    func sendMessage(_ message: [String: Any], completion: ((Error?) -> Void)? = nil) {
        db.collection("chatMessages").addDocument(data: message) { error in
            completion?(error)
        }
    }

    // MARK: - 2. 메시지 불러오기
    func fetchMessages(for userID: String, completion: @escaping ([[String: Any]]) -> Void) {
        db.collection("chatMessages")
            .whereField("userID", isEqualTo: userID)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let messages = documents.map { $0.data() }
                completion(messages)
            }
    }

    // MARK: - 3. 유저 질문 저장
    func saveSuggestedQuestion(_ question: [String: Any], completion: ((Error?) -> Void)? = nil) {
        db.collection("savedQuestions").addDocument(data: question) { error in
            completion?(error)
        }
    }

    // MARK: - 4. 추천 질문 불러오기
    func fetchSuggestedQuestions(completion: @escaping ([[String: Any]]) -> Void) {
        db.collection("questionSets")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let questions = documents.map { $0.data() }
                completion(questions)
            }
    }

    // MARK: - 5. 카테고리 응답 저장
    func saveCategoryReply(category: String, reply: String, completion: ((Error?) -> Void)? = nil) {
        let data: [String: Any] = [
            "category": category,
            "reply": reply,
            "timestamp": Timestamp(date: Date())
        ]
        db.collection("categoryReplies").addDocument(data: data) { error in
            if let error = error {
                print("❌ 카테고리 응답 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ 카테고리 응답 저장 성공")
            }
            completion?(error)
        }
    }
}


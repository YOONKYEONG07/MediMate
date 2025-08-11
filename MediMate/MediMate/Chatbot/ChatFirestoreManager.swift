import Foundation
import FirebaseFirestore

final class ChatFirestoreManager {
    private let db = Firestore.firestore()

    // MARK: - 1) 메시지 저장
    func sendMessage(_ message: [String: Any], completion: ((Error?) -> Void)? = nil) {
        db.collection("chatMessages").addDocument(data: message) { error in
            completion?(error)
        }
    }

    // MARK: - 2) 메시지 불러오기
    func fetchMessages(for userID: String, completion: @escaping ([[String: Any]]) -> Void) {
        db.collection("chatMessages")
            .whereField("userID", isEqualTo: userID)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.map { $0.data() } ?? []
                completion(messages)
            }
    }

    // MARK: - 3) 유저 질문 저장
    func saveSuggestedQuestion(_ question: [String: Any], completion: ((Error?) -> Void)? = nil) {
        db.collection("savedQuestions").addDocument(data: question) { error in
            completion?(error)
        }
    }

    // MARK: - 4) 추천 질문 불러오기
    func fetchSuggestedQuestions(completion: @escaping ([[String: Any]]) -> Void) {
        db.collection("questionSets")
            .addSnapshotListener { snapshot, _ in
                let questions = snapshot?.documents.map { $0.data() } ?? []
                completion(questions)
            }
    }

    // MARK: - 5) 카테고리 응답 저장
    func saveCategoryReply(category: String, reply: String, completion: ((Error?) -> Void)? = nil) {
        let data: [String: Any] = [
            "category": category,
            "reply": reply,
            "timestamp": Timestamp(date: Date())
        ]
        db.collection("categoryReplies").addDocument(data: data) { error in
            completion?(error)
        }
    }

    // MARK: - 6) 즐겨찾기 질문 저장 (세션ID 포함)
    func saveBookmarkedQuestion(userID: String, question: String, sessionId: String, completion: ((Error?) -> Void)? = nil) {
        let questionID = UUID().uuidString
        let data: [String: Any] = [
            "text": question,
            "timestamp": Timestamp(date: Date()),
            "sessionId": sessionId
        ]
        db.collection("savedQuestions")
            .document(userID)
            .collection("questions")
            .document(questionID)
            .setData(data) { error in
                completion?(error)
            }
    }

    // MARK: - 7) 즐겨찾기 불러오기 (현재 세션만)
    func fetchBookmarkedQuestions(userID: String, sessionId: String, completion: @escaping ([String]) -> Void) {
        db.collection("savedQuestions")
            .document(userID)
            .collection("questions")
            .whereField("sessionId", isEqualTo: sessionId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, _ in
                let questions = snapshot?.documents.compactMap { $0.data()["text"] as? String } ?? []
                completion(questions)
            }
    }

    // MARK: - 8) 즐겨찾기 전체 삭제(옵션)
    func clearAllBookmarks(userID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection("savedQuestions").document(userID).collection("questions")
        ref.getDocuments { snap, err in
            guard let docs = snap?.documents, err == nil else { completion(false); return }
            let batch = self.db.batch()
            docs.forEach { batch.deleteDocument($0.reference) }
            batch.commit { commitErr in
                completion(commitErr == nil)
            }
        }
    }
}


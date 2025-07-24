import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var text: String
    var isUser: Bool
    var timestamp: Date
}

struct SuggestedQuestion: Identifiable, Codable {
    @DocumentID var id: String?
    var category: String
    var question: String
}

class ChatFirestoreManager {
    private let db = Firestore.firestore()

    // MARK: 1. 메시지 저장
    func sendMessage(_ message: ChatMessage, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection("chatMessages").addDocument(from: message) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }

    // MARK: 2. 메시지 불러오기 (유저 기준 정렬)
    func fetchMessages(for userID: String, completion: @escaping ([ChatMessage]) -> Void) {
        db.collection("chatMessages")
            .whereField("userID", isEqualTo: userID)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let messages = documents.compactMap { try? $0.data(as: ChatMessage.self) }
                completion(messages)
            }
    }

    // MARK: 3. 추천 질문 저장
    func saveSuggestedQuestion(_ question: SuggestedQuestion, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection("savedQuestions").addDocument(from: question) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }

    // MARK: 4. 추천 질문 불러오기
    func fetchSuggestedQuestions(completion: @escaping ([SuggestedQuestion]) -> Void) {
        db.collection("questionSets")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let questions = documents.compactMap { try? $0.data(as: SuggestedQuestion.self) }
                completion(questions)
            }
    }
}

import Foundation
import FirebaseAuth
import FirebaseFirestore

class SearchHistoryViewModel: ObservableObject {
    @Published var searchQueries: [String] = []

    private let db = Firestore.firestore()

    func addSearchRecord(query: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("searchHistory").addDocument(data: [
            "query": query,
            "timestamp": Timestamp()
        ])
    }

    func fetchSearchHistory() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("searchHistory")
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    self?.searchQueries = []
                    return
                }
                self?.searchQueries = snapshot?.documents.compactMap { $0.data()["query"] as? String } ?? []
            }
    }
}

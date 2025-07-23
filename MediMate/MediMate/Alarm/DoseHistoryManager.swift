import Foundation
import FirebaseFirestore

class DoseHistoryManager {
    static let shared = DoseHistoryManager()
    private let key = "doseHistory"

    // ✅ 로컬 저장
    func saveRecord(_ record: DoseRecord) {
        var records = loadRecords()
        records.append(record)

        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
            print("✅ 로컬 저장됨: \(record)")
        }

        // ☁️ Firestore 저장도 함께 수행
        saveRecordToFirestore(medName: record.medicineName, takenTime: record.takenTime)
    }

    // ✅ 로컬 불러오기
    func loadRecords() -> [DoseRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DoseRecord].self, from: data) else {
            return []
        }
        print("📥 로컬 기록 불러옴: \(decoded.count)개")
        return decoded
    }
    
    func saveAll(_ records: [DoseRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
            print("🧹 전체 기록 덮어쓰기 완료")
        }
    }

    // ✅ Firestore에 복용 기록 저장
    func saveRecordToFirestore(medName: String, takenTime: Date) {
        let db = Firestore.firestore()
        let userID = "testUser123" // 로그인 붙으면 이 부분만 교체

        db.collection("doseHistory").addDocument(data: [
            "userID": userID,
            "medication": medName,
            "date": Timestamp(date: takenTime),
            "taken": true
        ]) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 저장 완료 - \(medName) \(takenTime)")
            }
        }
    }
}


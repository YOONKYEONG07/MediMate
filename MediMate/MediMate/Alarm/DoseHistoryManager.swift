import Foundation
import FirebaseFirestore

class DoseHistoryManager {
    static let shared = DoseHistoryManager()
    private let key = "doseHistory"
    private let db = Firestore.firestore()
    
    // ✅ 로컬 + Firestore 저장
    func saveRecord(_ record: DoseRecord) {
        var records = loadRecords()
        records.append(record)

        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
            print("✅ 로컬 저장됨: \(record)")
        }

        // ✅ taken 값을 전달하여 정확하게 저장
        saveRecordToFirestore(
            medName: record.medicineName,
            takenTime: record.takenTime,
            taken: record.taken
        )
    }
    
    func fetchTodayDoseRecords(userID: String, completion: @escaping ([DoseRecord]) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        db.collection("doseHistory")
            .whereField("userID", isEqualTo: userID)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else {
                    print("❌ 오늘 기록 불러오기 실패: \(error?.localizedDescription ?? "알 수 없음")")
                    completion([])
                    return
                }

                let records = docs.compactMap { doc -> DoseRecord? in
                    let data = doc.data()
                    guard let name = data["medication"] as? String,
                          let taken = data["taken"] as? Bool,
                          let timestamp = data["date"] as? Timestamp else {
                        return nil
                    }

                    return DoseRecord(
                        id: doc.documentID,
                        medicineName: name,
                        takenTime: timestamp.dateValue(),
                        taken: taken
                    )
                }

                completion(records)
            }
    }
    
    func updateDoseRecord(_ record: DoseRecord, completion: (() -> Void)? = nil) {
        let data: [String: Any] = [
            "medication": record.medicineName,
            "taken": record.taken,
            "date": Timestamp(date: record.takenTime)
        ]

        db.collection("doseHistory")
            .document(record.id)
            .setData(data, merge: true) { error in
                if let error = error {
                    print("❌ 기록 업데이트 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 복용 기록 수정됨: \(record.medicineName) → \(record.taken ? "복용 완료" : "복용 안함")")
                }
                completion?()
            }
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

    // ✅ Firestore에 복용 기록 저장 (복용/복용안함 모두 반영)
    func saveRecordToFirestore(medName: String, takenTime: Date, taken: Bool) {
        let userID = "testUser123"  // 로그인 연동 시 교체

        db.collection("doseHistory").addDocument(data: [
            "userID": userID,
            "medication": medName,
            "date": Timestamp(date: takenTime),
            "taken": taken
        ]) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 저장 완료 - \(medName) / taken: \(taken)")
            }
        }
    }
}


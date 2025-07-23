import Foundation
import FirebaseFirestore

class DoseRecordManager {
    static let shared = DoseRecordManager()
    private let db = Firestore.firestore()

    private init() {}

    // ✅ 복약 기록 저장
    func saveDoseRecord(userID: String, date: Date, medName: String, taken: Bool, completion: ((Error?) -> Void)? = nil) {
        let data: [String: Any] = [
            "userID": userID,
            "date": Timestamp(date: date),
            "medication": medName,
            "taken": taken
        ]

        db.collection("doseHistory").addDocument(data: data) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 저장 성공: \(medName) - \(taken ? "복용함" : "복용 안함")")
            }
            completion?(error)
        }
    }

    // ✅ 주간 복약 기록 조회 (날짜를 정규화해서 반환)
    func fetchWeeklyDoseRecords(userID: String, completion: @escaping ([Date: Bool]) -> Void) {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            completion([:])
            return
        }

        db.collection("doseHistory")
            .whereField("userID", isEqualTo: userID)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek))
            .getDocuments { snapshot, error in
                var result: [Date: Bool] = [:]

                if let documents = snapshot?.documents {
                    for doc in documents {
                        let data = doc.data()
                        if let timestamp = data["date"] as? Timestamp,
                           let taken = data["taken"] as? Bool {
                            let day = calendar.startOfDay(for: timestamp.dateValue())

                            // ❗ 기존에 이미 기록이 있으면 true 우선 처리
                            if let existing = result[day] {
                                result[day] = existing || taken
                            } else {
                                result[day] = taken
                            }
                        }
                    }
                } else {
                    print("❌ Firestore 기록 조회 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                }

                print("📥 불러온 Firestore 복약 기록 수: \(result.count)")
                completion(result)
            }
    }

    // ✅ 단일 날짜 복약 성공 여부 계산 (필요 시)
    func wasTaken(on date: Date, in records: [Date: Bool]) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return records[day] == true
    }
    
    // ✅ 특정 날짜의 복약 기록 조회 (홈화면 퍼센트 계산용)
    func fetchRecords(for userID: String, on date: Date, completion: @escaping ([DoseRecord]) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        db.collection("doseHistory")
            .whereField("userID", isEqualTo: userID)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore 오늘 기록 조회 실패: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let records = snapshot?.documents.compactMap { doc -> DoseRecord? in
                    let data = doc.data()
                    guard
                        let name = data["medication"] as? String,
                        let taken = data["taken"] as? Bool,
                        let timestamp = data["date"] as? Timestamp
                    else {
                        return nil
                    }

                    return DoseRecord(
                        id: doc.documentID,
                        medicineName: name,
                        takenTime: timestamp.dateValue(),
                        taken: taken
                    )
                } ?? []

                print("📦 오늘 복약 기록: \(records.count)개")
                completion(records)
            }
    }

}

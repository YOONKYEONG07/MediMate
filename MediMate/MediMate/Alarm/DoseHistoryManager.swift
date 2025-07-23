import Foundation

class DoseHistoryManager {
    static let shared = DoseHistoryManager()
    private let key = "doseHistory"

    func saveRecord(_ record: DoseRecord) {
        var records = loadRecords()
        records.append(record)

        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
            print("Saved Record: \(record)")  // 로그 추가
            print("All Records: \(records)")  // 모든 기록 출력
        }
    }

    func loadRecords() -> [DoseRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DoseRecord].self, from: data) else {
            return []
        }
        print("Loaded Records: \(decoded)")  // 로깅 추가: 불러온 데이터 확인
        return decoded
    }

    
}



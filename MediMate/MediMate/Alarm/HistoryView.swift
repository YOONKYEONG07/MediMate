import SwiftUI

struct HistoryView: View {
    @State private var records: [DoseRecord] = []

    var body: some View {
        NavigationView {
            List {
                // ✅ taken == true인 기록만 보여줌
                ForEach(records.filter { $0.taken }.sorted(by: { $0.takenTime > $1.takenTime })) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.medicineName)
                                .font(.headline)
                            Text(formatDate(record.takenTime))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            deleteRecord(record)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("복용 히스토리")
            .onAppear {
                records = DoseHistoryManager.shared.loadRecords()
            }
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
        return formatter.string(from: date)
    }

    func deleteRecord(_ record: DoseRecord) {
        records.removeAll { $0.id == record.id }
        DoseHistoryManager.shared.saveAll(records)
    }
}


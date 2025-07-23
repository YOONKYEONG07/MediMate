import SwiftUI
import Firebase
import FirebaseFirestore

struct TextSearchView: View {
    @State private var searchText: String = ""
    @State private var recentMeds: [String] = []
    @State private var popularMeds: [String] = []
    let userId = "user1"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: 탐색창
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("예: 타이레놀", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4), lineWidth: 1))


                    // MARK: 검색 버튼 - 검색창 바로 밑으로 이동
                    NavigationLink(destination: MedicationDetailView(medName: searchText)) {
                        Text("약 성분 분석하기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        saveSearchLog(searchText)
                    })
                    .disabled(searchText.isEmpty)


                    // MARK: 최근 검색한 약
                    Text("최근 내가 검색한 약")
                        .font(.title3)
                        .bold()

                    if recentMeds.isEmpty {
                        Text("최근 검색한 약이 없어요!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        ScrollView(showsIndicators: true) {
                            VStack(spacing: 8) {
                                ForEach(recentMeds, id: \.self) { med in
                                    HStack {
                                        NavigationLink(destination: MedicationDetailView(medName: med)) {
                                            Text(med)
                                                .foregroundColor(.primary)
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        Spacer()
                                        Button(action: {
                                            deleteRecentMed(med)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .frame(maxHeight: 160)
                    }

                    // MARK: 인기 검색 Top 3
                    if !popularMeds.isEmpty {
                        Text("많이 검색된 약 Top 3")
                            .font(.title3)
                            .bold()

                        VStack(spacing: 12) {
                            ForEach(Array(popularMeds.prefix(3).enumerated()), id: \.1) { index, med in
                                let imageName = med.lowercased().replacingOccurrences(of: " ", with: "_")

                                HStack(spacing: 12) {
                                    CapsulePillBadge(
                                        text: rankText(for: index),
                                        colorLeft: rankColor(for: index),
                                        colorRight: rankColor(for: index).opacity(0.7)
                                    )

                                    Text(med)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    NavigationLink(destination: MedicationDetailView(medName: med)) {
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 70)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 90)
                                .background(backgroundColor(for: index))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("텍스트로 검색")
            .onAppear {
                fetchRecentMeds()
                fetchPopularMeds()
            }
        }
    }

    // MARK: - 함수들

    func rankText(for index: Int) -> String {
        switch index {
        case 0: return "1위"
        case 1: return "2위"
        case 2: return "3위"
        default: return ""
        }
    }

    func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.orange // gold
        case 1: return Color.gray   // silver
        case 2: return Color.brown  // bronze
        default: return Color.primary
        }
    }

    func backgroundColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.yellow.opacity(0.15)
        case 1: return Color.gray.opacity(0.15)
        case 2: return Color.orange.opacity(0.15)
        default: return Color(.systemGray6)
        }
    }

    func saveSearchLog(_ medName: String) {
        let db = Firestore.firestore()
        let timestamp = Timestamp(date: Date())

        db.collection("searchLogs").addDocument(data: [
            "medName": medName,
            "timestamp": timestamp
        ])

        db.collection("recentSearches")
            .document(userId)
            .collection("logs")
            .addDocument(data: [
                "medName": medName,
                "timestamp": timestamp
            ]) { error in
                if let error = error {
                    print("❌ 최근 검색 기록 저장 실패: \(error)")
                } else {
                    print("✅ 최근 검색 기록 저장 성공: \(medName)")
                    fetchRecentMeds()
                }
            }
    }

    func fetchRecentMeds() {
        let db = Firestore.firestore()

        db.collection("recentSearches")
            .document(userId)
            .collection("logs")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 최근 검색어 불러오기 실패: \(error)")
                    return
                }

                let allMeds = snapshot?.documents.compactMap {
                    $0["medName"] as? String
                } ?? []

                var uniqueMeds: [String] = []
                var seen = Set<String>()
                for med in allMeds {
                    if !seen.contains(med) {
                        uniqueMeds.append(med)
                        seen.insert(med)
                    }
                }

                recentMeds = Array(uniqueMeds.prefix(10))
            }
    }

    func fetchPopularMeds() {
        let db = Firestore.firestore()

        db.collection("searchLogs")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 인기 약 불러오기 실패: \(error)")
                    return
                }

                let meds = snapshot?.documents.compactMap { $0["medName"] as? String } ?? []
                let counts = Dictionary(grouping: meds, by: { $0 }).mapValues { $0.count }
                let sorted = counts.sorted { $0.value > $1.value }.map { $0.key }
                popularMeds = Array(sorted.prefix(5))
            }
    }

    func deleteRecentMed(_ medName: String) {
        let db = Firestore.firestore()

        db.collection("recentSearches")
            .document(userId)
            .collection("logs")
            .whereField("medName", isEqualTo: medName)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 삭제 실패: \(error)")
                    return
                }

                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    print("❗️삭제할 문서 없음")
                    return
                }

                let batch = db.batch()
                for doc in docs {
                    batch.deleteDocument(doc.reference)
                }

                batch.commit { error in
                    if let error = error {
                        print("❌ 일괄 삭제 실패: \(error)")
                    } else {
                        print("✅ \(medName) 일괄 삭제 완료")
                        fetchRecentMeds()
                    }
                }
            }
    }
}

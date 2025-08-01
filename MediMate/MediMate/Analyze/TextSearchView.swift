import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct TextSearchView: View {
    @State private var searchText: String = ""
    @State private var recentMeds: [String] = []
    @State private var popularMeds: [String] = []

    // ✅ 현재 로그인한 사용자 UID
    var userId: String {
        return Auth.auth().currentUser?.uid ?? "unknown"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 검색창
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("예: 타이레놀", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4), lineWidth: 1))

                    // 검색 버튼
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

                    // 최근 검색
                    Text("최근 내가 검색한 약").font(.title3).bold()

                    if recentMeds.isEmpty {
                        Text("최근 검색한 약이 없어요!").font(.subheadline).foregroundColor(.gray)
                    } else {
                        ScrollView(showsIndicators: true) {
                            VStack(spacing: 8) {
                                ForEach(recentMeds, id: \.self) { med in
                                    HStack {
                                        let mapped = SupplementMapper.shared.mapToIngredient(med)

                                        NavigationLink(destination: MedicationDetailView(medName: mapped)) {
                                            Text(med)
                                                .foregroundColor(.primary)
                                                .font(.system(size: 16, weight: .medium))
                                        }

                                        Spacer()
                                        Button(action: {
                                            deleteRecentMed(med)
                                        }) {
                                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
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

                    // 인기 약
                    Text("많이 검색된 약 Top 5").font(.title3).bold()

                    VStack(spacing: 12) {
                        let paddedMeds = popularMeds + Array(repeating: "", count: max(0, 5 - popularMeds.count))
                        ForEach(Array(paddedMeds.prefix(5).enumerated()), id: \.offset) { index, med in
                            HStack(spacing: 12) {
                                CapsulePillBadge(
                                    text: rankText(for: index),
                                    colorLeft: rankColorLeft(for: index),
                                    colorRight: rankColorRight(for: index)
                                )

                                Text(med.isEmpty ? "—" : med)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(med.isEmpty ? .gray : .primary)

                                Spacer()

                                if !med.isEmpty {
                                    NavigationLink(destination: MedicationDetailView(medName: med)) {
                                        Image(systemName: "chevron.right").foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
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

    // MARK: - 랭킹 관련
    func rankText(for index: Int) -> String {
        switch index {
        case 0: return "🥇 1위"
        case 1: return "🥈 2위"
        case 2: return "🥉 3위"
        case 3: return "4위"
        case 4: return "5위"
        default: return ""
        }
    }

    func rankColorLeft(for index: Int) -> Color {
        switch index {
        case 0: return .orange
        case 1: return .gray
        case 2: return .brown
        case 3: return Color.gray.opacity(0.3)
        case 4: return Color.teal.opacity(0.3)
        default: return .primary
        }
    }

    func rankColorRight(for index: Int) -> Color {
        switch index {
        case 0: return .orange.opacity(0.7)
        case 1: return .gray.opacity(0.7)
        case 2: return .brown.opacity(0.7)
        case 3: return .blue
        case 4: return .cyan
        default: return .primary
        }
    }

    // MARK: - 검색 기록 저장
    func saveSearchLog(_ medName: String) {
        let timestamp = Timestamp(date: Date())
        let db = Firestore.firestore()

        // 전체 검색 로그
        db.collection("searchLogs").addDocument(data: [
            "medName": medName,
            "timestamp": timestamp
        ])

        // 🔹 사용자별 검색 로그
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

        // 인기 약 처리
        let popularRef = db.collection("popularMeds").document(medName)
        popularRef.getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                let currentCount = document.data()?["count"] as? Int ?? 0
                popularRef.updateData(["count": currentCount + 1])
            } else {
                popularRef.setData(["medName": medName, "count": 1])
            }
        }
    }

    // MARK: - 사용자별 최근 검색어 불러오기
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

    // MARK: - 인기 약 불러오기
    func fetchPopularMeds() {
        let db = Firestore.firestore()
        db.collection("popularMeds")
            .order(by: "count", descending: true)
            .limit(to: 5)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 인기 약 불러오기 실패: \(error)")
                    return
                }

                let sorted = snapshot?.documents.compactMap { $0.documentID } ?? []
                popularMeds = Array(sorted.prefix(5))
            }
    }

    // MARK: - 최근 검색 기록 삭제
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
